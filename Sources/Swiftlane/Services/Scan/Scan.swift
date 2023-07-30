//

import Combine
import Foundation

import Simulator
import SwiftlaneCore
import Xcodebuild

public enum ScanError: Error {
    case testsResultsXCResultPathNotFound
    case testsResultsJUnitPathNotFound
}

// sourcery: AutoMockable
public protocol ScanProtocol {}

public class Scan: ScanProtocol {
    private let filesManager: FSManager
    private let logPathFactory: LogPathFactoring
    private let shell: ShellExecuting
    private let logger: Logging
    private let timeMeasurer: TimeMeasuring

    private let config: Config
    private let runner: TestsRunner

    public init(
        filesManager: FSManager,
        logPathFactory: LogPathFactoring,
        shell: ShellExecuting,
        logger: Logging,
        timeMeasurer: TimeMeasuring,
        config: Config,
        runner: TestsRunner
    ) {
        self.filesManager = filesManager
        self.logPathFactory = logPathFactory
        self.shell = shell
        self.logger = logger
        self.timeMeasurer = timeMeasurer
        self.config = config
        self.runner = runner
    }

    public func run() throws -> TestsRunner.TestRunResult {
        try? Simulator.shutdownAll(shell: shell)

        defer { try? Simulator.shutdownAll(shell: shell) }

        let result = runTests(on: config.referenceSimulator)

        try copyResults(
            testsResults: result,
            mergedXCResultPath: config.mergedXCResultPath,
            mergedJUnitPath: config.mergedJUnitPath
        )

        do {
            try collectSystemLogs(runResult: result)
        } catch {
            // TODO: should we throw this upwards or just ignore?
            logger.warn("Ignored error: \"\(String(reflecting: error))\"")
        }

        if result.result.error == nil {
            logger.success("Scan: Testing succeeded")
        }

        return result
    }

    private func runTests(on simulator: Simulator) -> TestsRunner.TestRunResult {
        timeMeasurer.measure(description: "Running tests on \(simulator.device.name)") {
            self.runner.runTests(simulator: simulator, tests: [])
        }
    }

    /// Collect `system.log` files of all used simulators into results directory.
    private func collectSystemLogs(runResult: TestsRunner.TestRunResult) throws {
        let targetSystemLogPath = logPathFactory.makeSystemLogPath(
            logsDir: config.logsPath,
            scheme: config.scheme,
            simulatorName: runResult.simulator.device.name
        )

        let systemLog = try AbsolutePath(runResult.simulator.device.logPath)
            .appending(path: "system.log")

        logger.info("Collecting '\(systemLog)'...")
        try filesManager.copy(systemLog, to: targetSystemLogPath)
    }

    /// Copy `.xcresults` and `.junit` from derived data into specified paths.
    private func copyResults(
        testsResults: TestsRunner.TestRunResult,
        mergedXCResultPath: AbsolutePath,
        mergedJUnitPath: AbsolutePath
    ) throws {
        guard let xcresultPath = testsResults.xcresultPath else { throw ScanError.testsResultsXCResultPathNotFound }
        do {
            try filesManager.copy(xcresultPath, to: mergedXCResultPath)
        } catch {
            logger.error("Error copy `.xcresults`: \"\(String(reflecting: error))\"")
        }

        if testsResults.result.error == nil || testsResults.result.error?.reason == .testingFailed {
            guard let junitPath = testsResults.junitPath else { throw ScanError.testsResultsJUnitPathNotFound }
            do {
                try filesManager.copy(junitPath, to: mergedJUnitPath)
            } catch {
                logger.error("Error copy `.junit`: \"\(String(reflecting: error))\"")
            }
        }
    }
}
