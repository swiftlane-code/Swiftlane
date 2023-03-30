//

import Foundation

import Simulator
import SwiftlaneCore
import Xcodebuild

public final class RunTestsTask {
    private let simulatorProvider: SimulatorProviding
    private let logger: Logging
    private let shell: ShellExecuting
    private let exitor: Exiting

    private let config: Config

    public init(
        simulatorProvider: SimulatorProviding,
        logger: Logging,
        shell: ShellExecuting,
        exitor: Exiting,
        config: RunTestsTask.Config
    ) {
        self.simulatorProvider = simulatorProvider
        self.logger = logger
        self.shell = shell
        self.exitor = exitor
        self.config = config
    }

    public func run() throws {
        logger.important("Using scheme: \(config.scheme), testPlan: \(config.testPlan ?? "<nil>")")

        let filesManager = FSManager(
            logger: logger,
            fileManager: FileManager.default
        )

        let builderConfig = Builder.Config(
            project: config.projectFile,
            scheme: config.scheme,
            derivedDataPath: config.derivedDataDir,
            logsPath: config.logsDir,
            configuration: nil,
            xcodebuildFormatterPath: config.xcodebuildFormatterPath
        )

        let runnerConfig = TestsRunner.Config(
            builderConfig: builderConfig,
            projectDirPath: config.projectDir,
            testRunsDerivedDataPath: config.testRunsDerivedDataDir,
            testRunsLogsPath: config.logsDir,
            testPlan: config.testPlan,
            testWithoutBuilding: config.testWithoutBuilding,
            xcodebuildFormatterPath: config.xcodebuildFormatterPath,
            testingTimeout: config.testingTimeout
        )

        let iphone = try simulatorProvider.getAllDevices().first {
            $0.device.name == config.deviceModel && $0.runtime.version == config.osVersion
        }.unwrap(errorDescription: "Simulator \(config.deviceModel) with iOS \(config.osVersion) not found.")

        let logPathFactory = LogPathFactory(filesManager: filesManager)

        // MARK: Finders

        let xcTestRunFinder = XCTestRunFinder(
            filesManager: filesManager
        )
        let xcTestRunParser = XCTestRunParser(
            filesManager: filesManager,
            xcTestRunFinder: xcTestRunFinder
        )
        let xcTestPlanFinder = XCTestPlanFinder(
            filesManager: filesManager,
            xctestRunFinder: xcTestRunFinder,
            xcTestRunParser: xcTestRunParser
        )

        // MARK: Parsers

        let xcTestParser = XCTestParser(
            shell: shell,
            filesManager: filesManager,
            logger: logger
        )
        let xcTestPlanParser = XCTestPlanParser(
            filesManager: filesManager
        )

        // MARK: Services

        let xcTestPlanService = XCTestPlanService(
            testPlanFinder: xcTestPlanFinder,
            testPlanParser: xcTestPlanParser
        )

        let xcTestService = XCTestService(
            xctestParser: xcTestParser,
            xcTestRunFinder: xcTestRunFinder,
            xcTestRunParser: xcTestRunParser
        )

        let junitService = JUnitService(filesManager: filesManager)

        // MARK: ====

        let timeMeasurer = TimeMeasurer(logger: logger)

        let xcodebuildCommand = XcodebuildCommandProducer(isUseRosetta: config.isUseRosetta)

        let testsRunner = TestsRunner(
            filesManager: filesManager,
            xcTestService: xcTestService,
            logPathFactory: logPathFactory,
            shell: shell,
            config: runnerConfig,
            xcodebuildCommand: xcodebuildCommand,
            errorParser: XcodebuildErrorParser()
        )

        let results: [TestsRunner.TestRunResult]

        if config.useMultiScan {
            let scanConfig = MultiScan.Config(
                builderConfig: builderConfig,
                testsRunnerConfig: runnerConfig,
                referenceSimulator: iphone,
                simulatorsCount: config.simulatorsCount,
                resultsDir: config.resultsDir,
                mergedXCResultPath: config.mergedXCResultPath,
                mergedJUnitPath: config.mergedJUnitPath
            )

            let xcodebuildCommand = XcodebuildCommandProducer(isUseRosetta: config.isUseRosetta)

            let multiScan = MultiScan(
                filesManager: filesManager,
                logPathFactory: logPathFactory,
                simulatorProvider: simulatorProvider,
                testPlanService: xcTestPlanService,
                junitService: junitService,
                shell: shell,
                logger: logger,
                timeMeasurer: timeMeasurer,
                config: scanConfig,
                builder: Builder(
                    filesManager: filesManager,
                    logPathFactory: logPathFactory,
                    shell: shell,
                    logger: logger,
                    timeMeasurer: timeMeasurer,
                    xcodebuildCommand: xcodebuildCommand,
                    config: builderConfig
                ),
                runner: testsRunner,
                projectDir: config.projectDir
            )

            results = try multiScan.run()
        } else {
            let scanConfig = Scan.Config(
                referenceSimulator: iphone,
                resultsDir: config.resultsDir,
                logsPath: config.logsDir,
                scheme: config.scheme,
                mergedXCResultPath: config.mergedXCResultPath,
                mergedJUnitPath: config.mergedJUnitPath
            )

            let scan = Scan(
                filesManager: filesManager,
                logPathFactory: logPathFactory,
                shell: shell,
                logger: logger,
                timeMeasurer: timeMeasurer,
                config: scanConfig,
                runner: testsRunner
            )

            results = [try scan.run()]
        }

        let errors = results.compactMap(\.result.error)
        errors.forEach {
            logger.logError($0)
        }
        if let worstCode = errors.map(\.reason.rawValue).min() {
            Exitor().exit(with: Int32(worstCode))
        }
        logger.success("RunTestsTask: Success.")
    }
}
