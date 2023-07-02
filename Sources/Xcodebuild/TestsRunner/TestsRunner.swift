//

import Combine
import Foundation

import Simulator
import SwiftlaneCore

public protocol TestsRunnerProtocol {
    func getBuiltTests() throws -> AnyPublisher<[XCTestFunction], Error>
    func runTests(simulator: Simulator, tests: [XCTestFunction]) -> TestsRunner.TestRunResult
}

public class TestsRunner: TestsRunnerProtocol {
    let filesManager: FSManaging
    let xcTestService: XCTestServicing
    let logPathFactory: LogPathFactory
    let shell: ShellExecuting
    let xcodebuildCommand: XcodebuildCommandProducing
    let errorParser: XcodebuildErrorParsing

    public let config: Config

    public init(
        filesManager: FSManaging,
        xcTestService: XCTestServicing,
        logPathFactory: LogPathFactory,
        shell: ShellExecuting,
        config: Config,
        xcodebuildCommand: XcodebuildCommandProducing,
        errorParser: XcodebuildErrorParsing
    ) {
        self.filesManager = filesManager
        self.xcTestService = xcTestService
        self.logPathFactory = logPathFactory
        self.shell = shell
        self.config = config
        self.xcodebuildCommand = xcodebuildCommand
        self.errorParser = errorParser
    }

    private func makeTestRunDerivedDataPath(simulatorUDID: String) -> AbsolutePath {
        config.testRunsDerivedDataPath.appending(path: try! RelativePath(config.scheme + "_" + simulatorUDID))
    }

    public func getBuiltTests() throws -> AnyPublisher<[XCTestFunction], Error> {
        if config.testWithoutBuilding {
            return try xcTestService.parseTests(derivedDataPath: config.buildDerivedDataPath)
        }
        return .just([])
    }

    public func runTests(simulator: Simulator, tests: [XCTestFunction]) -> TestRunResult {
        try! filesManager.mkdir(config.testRunsLogsPath)

        let testRunDerivedDataPath: AbsolutePath
        if config.testWithoutBuilding {
            testRunDerivedDataPath = makeTestRunDerivedDataPath(simulatorUDID: simulator.device.udid)
        } else {
            testRunDerivedDataPath = config.buildDerivedDataPath
        }

        try! filesManager.mkdir(testRunDerivedDataPath)

        let runLogsPaths = logPathFactory.makeTestRunLogPath(
            logsDir: config.testRunsLogsPath,
            scheme: config.scheme,
            simulatorName: simulator.device.name
        )

        let junitPath = logPathFactory.makeJunitReportPath(
            logsDir: config.testRunsLogsPath,
            scheme: config.scheme,
            simulatorName: simulator.device.name
        )

        let result: Result<Void, XcodebuildError>
        do {
            if config.testWithoutBuilding {
                try filesManager.createSymlink(
                    testRunDerivedDataPath.appending(path: .init("Build")),
                    pointingTo: config.buildDerivedDataPath.appending(path: .init("Build"))
                )
            }

            let testPlanArgument = config.testPlan
                .map { "-testPlan " + $0 } ?? ""

            let onlyTestingArguments = tests
                .map { "-only-testing:" + $0.name }
                .joined(separator: " ")

            // -disable-concurrent-destination-testing \

            /// # xcbeautfy's bug:
            /// `xcbeautfy` treats any path provided to `--report-path` as a path
            /// relative to current working directory.
            let junitReportRelativePath = try junitPath.deletingLastComponent.relative(to: AbsolutePath(FileManager.default.currentDirectoryPath)).string
            let junitFileName = junitPath.lastComponent.string

            try shell.run(
                [
                    "set -o pipefail && \(xcodebuildCommand.produce())",
                    "-destination 'platform=iOS Simulator,id=\(simulator.device.udid)'",
                    "-derivedDataPath \(testRunDerivedDataPath)",
                    "-disable-concurrent-destination-testing",
                    "-enableCodeCoverage YES",
                    "-project '\(config.project)'",
                    "-scheme '\(config.scheme)'",
                    "-parallel-testing-enabled NO",
                    "\(onlyTestingArguments)",
                    "\(testPlanArgument)",
                    config.testWithoutBuilding ? "test-without-building" : "test",
                    "| tee '\(runLogsPaths.stdout)'",
                    "| \(config.xcodebuildFormatterCommand) --is-ci --report junit",
                    "--report-path '\(junitReportRelativePath)' --junit-report-filename '\(junitFileName)'",
                ],
                log: .commandAndOutput(outputLogLevel: .verbose),
                logPrefix: "<device: \(simulator.device.name)> ",
                logStdErrToFile: runLogsPaths.stderr,
                executionTimeout: config.testingTimeout
            )

            result = .success(())
        } catch {
            result = .failure(errorParser.transformError(error))
        }

        let xcresultPath = try? filesManager.find(testRunDerivedDataPath).first { $0.hasSuffix(".xcresult") }

        return TestRunResult(
            simulator: simulator,
            tests: tests,
            xcresultPath: xcresultPath,
            runLogsPaths: runLogsPaths,
            junitPath: junitPath,
            result: result
        )
    }
}
