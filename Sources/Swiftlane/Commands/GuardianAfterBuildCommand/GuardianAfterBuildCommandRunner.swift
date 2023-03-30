//

import Foundation
import Git
import GitLabAPI
import Guardian
import SwiftlaneCore
import Yams

public struct GuardianAfterBuildCommandRunner: CommandRunnerProtocol {
    public func run(
        params: GuardianAfterBuildCommandParamsAccessing,
        commandConfig: GuardianAfterBuildCommandConfig,
        sharedConfig: SharedConfigData,
        logger: Logging
    ) throws {
        let sigIntHandler = SigIntHandler(logger: logger)

        let xcodeChecker = XcodeChecker()

        let filesManager = FSManager(
            logger: logger,
            fileManager: FileManager.default
        )

        let shell = ShellExecutor(
            sigIntHandler: sigIntHandler,
            logger: logger,
            xcodeChecker: xcodeChecker,
            filesManager: filesManager
        )

        let environmentValueReader = EnvironmentValueReader()

        let gitlabCIEnvironmentReader = GitLabCIEnvironmentReader(environmentValueReading: environmentValueReader)

        let git = Git(
            shell: shell,
            filesManager: filesManager,
            diffParser: GitDiffParser(logger: logger)
        )

        let config = GuardianAfterBuildTask.Config(
            projectDir: params.sharedConfigOptions.projectDir,
            buildErrorsCheckerConfig: BuildErrorsChecker.Config(
                projectDir: params.sharedConfigOptions.projectDir,
                derivedDataPath: sharedConfig.paths.derivedDataDir,
                htmlReportOutputDir: sharedConfig.paths.xclogparserHTMLReportDir,
                jsonReportOutputFilePath: sharedConfig.paths.xclogparserJSONReport
            ),
            buildWarningsCheckerConfig: BuildWarningsChecker.Config(
                projectDir: params.sharedConfigOptions.projectDir,
                derivedDataPath: sharedConfig.paths.derivedDataDir,
                jsonReportOutputFilePath: sharedConfig.paths.xclogparserJSONReport,
                decodableConfig: commandConfig.buildWarningCheckerConfig
            ),
            unitTestsResultsCheckerConfig: .init(
                junitPath: sharedConfig.paths.mergedJUnit,
                projectDir: params.sharedConfigOptions.projectDir
            ),
            exitCodeCheckerConfig: .init(
                projectDir: params.sharedConfigOptions.projectDir,
                logsDir: sharedConfig.paths.logsDir
            ),
            changesCoverageLimitCheckerConfig: .init(
                decodableConfig: commandConfig.changesCoverageLimitCheckerConfig,
                projectDir: params.sharedConfigOptions.projectDir,
                excludedFileNameMatchers: commandConfig.targetsCoverageLimitCheckerConfig.defaultFilters
            ),
            targetsCoverageLimitCheckerConfig: .init(
                decodableConfig: commandConfig.targetsCoverageLimitCheckerConfig,
                projectDir: params.sharedConfigOptions.projectDir,
                xcresultDir: sharedConfig.paths.resultsDir,
                xccovTempCoverageFilePath: sharedConfig.paths.xccovFile
            )
        )

        let mergeRequestReporter = MergeRequestReporter(
            logger: logger,
            gitlabApi: try GitLabAPIClient(logger: logger),
            gitlabCIEnvironment: gitlabCIEnvironmentReader,
            reportFactory: MergeRequestReportFactory(),
            publishEmptyReport: true
        )

        let coverageCalculator = TargetCoverageCalculator(
            logger: logger,
            config: TargetCoverageCalculator.Config(
                defaultFilters: commandConfig.targetsCoverageLimitCheckerConfig.defaultFilters,
                excludeFilesFilters: commandConfig.targetsCoverageLimitCheckerConfig.excludeFilesFilters,
                targetCoverageLimits: commandConfig.targetsCoverageLimitCheckerConfig.targetCoverageLimits,
                projectDir: params.sharedConfigOptions.projectDir
            )
        )

        let targetCoverageChecker = TargetsCoverageLimitChecker(
            logger: logger,
            filesManager: filesManager,
            shell: shell,
            xccov: XCCOVService(filesManager: filesManager, shell: shell),
            targetsFilterer: TargetsCoverageTargetsFilterer(),
            coverageCalculator: coverageCalculator,
            reporter: TargetCoverageReporter(reporter: mergeRequestReporter),
            config: config.targetsCoverageLimitCheckerConfig
        )

        let changesCoverageChecker = ChangesCoverageLimitChecker(
            logger: logger,
            gitlabCIEnvironmentReader: gitlabCIEnvironmentReader,
            git: git,
            slather: SlatherService(filesManager: filesManager),
            reporter: ChangesCoverageReporter(reporter: mergeRequestReporter),
            config: config.changesCoverageLimitCheckerConfig
        )

        let xclogparserService = XCLogParserService(filesManager: filesManager, shell: shell)

        let buildErrorsChecker = BuildErrorsChecker(
            xclogparser: xclogparserService,
            reporter: BuildErrorsReporter(
                reporter: mergeRequestReporter,
                issueFormatter: XCLogParserIssueMarkdownFormatter()
            ),
            logger: logger,
            config: config.buildErrorsCheckerConfig
        )

        let buildWarningsChecker = BuildWarningsChecker(
            xclogparser: xclogparserService,
            reporter: BuildWarningsReporter(
                reporter: mergeRequestReporter,
                issueFormatter: XCLogParserIssueMarkdownFormatter(),
                failBuildWhenWarningsDetected: commandConfig.buildWarningCheckerConfig.failBuildWhenWarningsDetected
            ),
            logger: logger,
            config: config.buildWarningsCheckerConfig
        )

        let unitTestsResultsReporter = UnitTestsResultsReporter(reporter: mergeRequestReporter)

        let unitTestsChecker = UnitTestsResultsChecker(
            junitService: JUnitService(filesManager: filesManager),
            gitlabCIEnvironmentReader: gitlabCIEnvironmentReader,
            reporter: unitTestsResultsReporter,
            config: config.unitTestsResultsCheckerConfig
        )

        let exitCodeChecker = UnitTestsExitCodeChecker(
            checkerData: .init(unitTestsExitCode: params.unitTestsExitCode),
            environmentValueReader: environmentValueReader,
            gitlabCIEnvironmentReader: gitlabCIEnvironmentReader,
            reporter: mergeRequestReporter,
            filesManager: filesManager,
            config: config.exitCodeCheckerConfig
        )

        let task = GuardianAfterBuildTask(
            logger: logger,
            mergeRequestReporter: mergeRequestReporter,
            targetCoverageChecker: targetCoverageChecker,
            changesCoverageChecker: changesCoverageChecker,
            buildErrorsChecker: buildErrorsChecker,
            buildWarningsChecker: buildWarningsChecker,
            unitTestsChecker: unitTestsChecker,
            exitCodeChecker: exitCodeChecker,
            config: config,
            gitlabCIEnvironmentReader: gitlabCIEnvironmentReader,
            environmentValueReader: environmentValueReader
        )

        try task.run()
    }
}
