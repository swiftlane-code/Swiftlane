//

import Foundation

import Simulator
import SwiftlaneCore

// sourcery: AutoMockable
public protocol BuilderProtocol {
    var config: Builder.Config { get }

    func cleanDerivedData()
    func resolveSPMDependencies(simulator: Simulator) throws
    func showBuildSettings(simulator: Simulator) throws
    func buildForTesting(simulator: Simulator) throws
    func buildForRunning(simulator: Simulator) throws
    func build(forTesting: Bool, destination: BuildDestination) throws
    func archive(
        buildConfiguration: String,
        archivePath: AbsolutePath
    ) throws
}

public enum BuildDestination {
    case simulator(Simulator)
    case genericIOSDevice

    public var xcodebuildDestinationOption: String {
        switch self {
        case let .simulator(simulator):
            return "-destination 'platform=iOS Simulator,id=\(simulator.device.udid),OS=\(simulator.runtime.version)'"
        case .genericIOSDevice:
            return "-destination 'generic/platform=iOS'"
        }
    }

    public var humanDescription: String {
        switch self {
        case let .simulator(simulator):
            return "iOS \(simulator.runtime.version) Simulator - \(simulator.device.name) \(simulator.device.udid)"
        case .genericIOSDevice:
            return "Generic iOS device"
        }
    }
}

public class Builder: BuilderProtocol {
    let filesManager: FSManaging
    let logPathFactory: LogPathFactory
    let shell: ShellExecuting
    let logger: Logging
    let timeMeasurer: TimeMeasurer
    let xcodebuildCommand: XcodebuildCommandProducing
    public let config: Config

    public init(
        filesManager: FSManaging,
        logPathFactory: LogPathFactory,
        shell: ShellExecuting,
        logger: Logging,
        timeMeasurer: TimeMeasurer,
        xcodebuildCommand: XcodebuildCommandProducing,
        config: Config
    ) {
        self.filesManager = filesManager
        self.logPathFactory = logPathFactory
        self.shell = shell
        self.logger = logger
        self.timeMeasurer = timeMeasurer
        self.xcodebuildCommand = xcodebuildCommand
        self.config = config
    }

    public func cleanDerivedData() {
        try? filesManager.delete(config.derivedDataPath)
    }

    public func resolveSPMDependencies(simulator _: Simulator) throws {
        try timeMeasurer.measure(description: "Resolving SPM dependencies for scheme '\(config.scheme)'") {
            _ = try shell.run([
                xcodebuildCommand.produce(),
                "-resolvePackageDependencies",
                "-scheme", config.scheme.quoted,
                "-project", config.project.string.quoted,
                "-derivedDataPath", config.derivedDataPath.string.quoted,
            ], log: .commandAndOutput(outputLogLevel: .verbose))
        }
    }

    public func showBuildSettings(simulator _: Simulator) throws {
        logger.verbose("Show build settings for scheme '\(config.scheme)' in '\(config.project)':")

        _ = try shell.run([
            xcodebuildCommand.produce(),
            "-showBuildSettings",
            "-scheme", config.scheme.quoted,
            "-project", config.project.string.quoted,
            "-derivedDataPath", config.derivedDataPath.string.quoted,
        ], log: .commandAndOutput(outputLogLevel: .verbose))
    }

    /// Build scheme specified in ``config``.
    /// - Parameters:
    ///   - forTesting: build for testing or running.
    ///   - destination: build destination.
    public func build(
        forTesting: Bool,
        destination: BuildDestination
    ) throws {
        let message = [
            "Build '\(config.scheme)' for ",
            forTesting ? "testing" : "running",
            "on", destination.humanDescription.quoted,
        ].joined(separator: " ")

        try timeMeasurer.measure(description: message) {
            let logsPaths = logPathFactory.makeBuildLogPath(logsDir: config.logsPath, scheme: config.scheme)

            _ = try shell.run(
                [
                    "set -o pipefail && " + xcodebuildCommand.produce(),
                    "-scheme", config.scheme.quoted,
                    "-project", config.project.string.quoted,
                    "-derivedDataPath", config.derivedDataPath.string.quoted,
                    destination.xcodebuildDestinationOption,
                    config.configuration.map { "-configuration " + $0 } ?? "",
                    forTesting ? "-enableCodeCoverage YES" : "",
                    forTesting ? "build-for-testing" : "build",
                    "| tee '\(logsPaths.stdout)'",
                    "| \(config.xcodebuildFormatterPath.string)",
                ],
                log: .commandAndOutput(outputLogLevel: .verbose),
                logStdErrToFile: logsPaths.stderr
            )
        }
    }

    public func buildForTesting(simulator: Simulator) throws {
        try build(forTesting: true, destination: .simulator(simulator))
    }

    public func buildForRunning(simulator: Simulator) throws {
        try build(forTesting: false, destination: .simulator(simulator))
    }

    public func archive(
        buildConfiguration: String,
        archivePath: AbsolutePath
    ) throws {
        try timeMeasurer.measure(description: "Archiving \(buildConfiguration) configuration of scheme '\(config.scheme)'") {
            let logsPaths = logPathFactory.makeArchiveLogPath(
                logsDir: config.logsPath,
                scheme: config.scheme,
                configuration: buildConfiguration
            )

            try shell.run(
                [
                    "set -o pipefail && " + xcodebuildCommand.produce(),
                    "-scheme", config.scheme.quoted,
                    "-project", config.project.string.quoted,
                    "-derivedDataPath", config.derivedDataPath.string.quoted,
                    BuildDestination.genericIOSDevice.xcodebuildDestinationOption,
                    "-configuration " + buildConfiguration.quoted,
                    "-archivePath " + archivePath.string.quoted,
                    "clean archive",
                    "| tee '\(logsPaths.stdout)'",
                    "| \(config.xcodebuildFormatterPath.string)",
                ],
                log: .commandAndOutput(outputLogLevel: .verbose),
                logStdErrToFile: logsPaths.stderr
            )
        }

        logger.success("xcarchive created at path \(archivePath.string.quoted).")
    }
}
