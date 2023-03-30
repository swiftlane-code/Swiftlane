//

import Foundation

import Simulator
import SwiftlaneCore
import Xcodebuild

public final class MeasureBuildTimeTask {
    private let simulatorProvider: SimulatorProviding
    private let logger: Logging
    private let shell: ShellExecuting

    private let projectFile: AbsolutePath
    private let derivedDataDir: AbsolutePath
    private let logsDir: AbsolutePath
    private let scheme: String
    private let deviceModel: String
    private let osVersion: String
    private let iterations: Int
    private let buildForTesting: Bool
    private let isUseRosetta: Bool
    private let xcodebuildFormatterPath: AbsolutePath

    public init(
        simulatorProvider: SimulatorProviding,
        logger: Logging,
        shell: ShellExecuting,
        projectFile: AbsolutePath,
        derivedDataDir: AbsolutePath,
        logsDir: AbsolutePath,
        scheme: String,
        deviceModel: String,
        osVersion: String,
        iterations: Int,
        buildForTesting: Bool,
        isUseRosetta: Bool,
        xcodebuildFormatterPath: AbsolutePath
    ) {
        self.simulatorProvider = simulatorProvider
        self.logger = logger
        self.shell = shell
        self.projectFile = projectFile
        self.derivedDataDir = derivedDataDir
        self.logsDir = logsDir
        self.scheme = scheme
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.iterations = iterations
        self.buildForTesting = buildForTesting
        self.isUseRosetta = isUseRosetta
        self.xcodebuildFormatterPath = xcodebuildFormatterPath
    }

    private func makeBuilder() throws -> BuilderProtocol {
        let filesManager = FSManager(
            logger: logger,
            fileManager: FileManager.default
        )

        let builderConfig = Builder.Config(
            project: projectFile,
            scheme: scheme,
            derivedDataPath: derivedDataDir,
            logsPath: logsDir,
            configuration: nil,
            xcodebuildFormatterPath: xcodebuildFormatterPath
        )

        let logPathFactory = LogPathFactory(filesManager: filesManager)

        let xcodebuildCommand = XcodebuildCommandProducer(isUseRosetta: isUseRosetta)

        return Builder(
            filesManager: filesManager,
            logPathFactory: logPathFactory,
            shell: shell,
            logger: logger,
            timeMeasurer: TimeMeasurer(logger: logger),
            xcodebuildCommand: xcodebuildCommand,
            config: builderConfig
        )
    }

    public func run() throws {
        let builder = try makeBuilder()

        let elapsedLogger = TimeMeasurer(logger: logger)

        let destinationSimulator = try simulatorProvider.getAllDevices().first {
            $0.device.name == deviceModel && $0.runtime.version == osVersion
        }.unwrap()

        // MARK: ====

        var measures = [DateComponents]()

        for i in 1 ... iterations {
            builder.cleanDerivedData()

            let start = Date()

            try elapsedLogger.measure(description: "Building iteration \(i)/\(iterations)") {
                if buildForTesting {
                    try builder.buildForTesting(simulator: destinationSimulator)
                } else {
                    try builder.buildForRunning(simulator: destinationSimulator)
                }
            }

            let difference = Calendar.current.dateComponents([.second], from: start, to: Date())
            measures.append(difference)
        }

        let iterationsSeconds = measures.map { $0.second! }
        let totalTime = iterationsSeconds.reduce(0, +)
        let averageTime = totalTime / iterations

        iterationsSeconds.enumerated().forEach { idx, seconds in
            logger.warn("Iteration \(idx + 1) took \(seconds) seconds.")
        }

        logger.important([
            "Building", scheme,
            buildForTesting ? "for testing" : "for running",
            iterations, "times",
            "took", totalTime, "seconds.",
            "Average:", averageTime, "seconds.",
        ].map { "\($0)" }.joined(separator: " "))
    }
}
