//

import AppStoreConnectAPI
import AppStoreConnectJWT
import Foundation
import Git
import GitLabAPI
import Guardian
import JiraAPI
import MattermostAPI
import Provisioning
import Simulator
import SwiftlaneCore
import Xcodebuild

public enum TasksFactory {
    public static func makeRunTestsTask(
        projectDir: AbsolutePath,
        commandConfig: RunTestsCommandConfig,
        sharedConfig: SharedConfigData,
        useRosetta: Bool = false,
        testingTimeout: TimeInterval = 3600
    ) throws -> RunTestsTask {
        let config = RunTestsTask.Config(
            projectDir: projectDir,
            projectFile: sharedConfig.paths.projectFile,
            scheme: commandConfig.scheme,
            deviceModel: commandConfig.deviceModel,
            osVersion: commandConfig.osVersion,
            simulatorsCount: commandConfig.simulatorsCount,
            testPlan: commandConfig.testPlan,
            derivedDataDir: sharedConfig.paths.derivedDataDir,
            testRunsDerivedDataDir: sharedConfig.paths.testRunsDerivedDataDir,
            logsDir: sharedConfig.paths.logsDir,
            resultsDir: sharedConfig.paths.resultsDir,
            mergedXCResultPath: sharedConfig.paths.mergedXCResult,
            mergedJUnitPath: sharedConfig.paths.mergedJUnit,
            testWithoutBuilding: commandConfig.useMultiScan,
            useMultiScan: commandConfig.useMultiScan,
            xcodebuildFormatterCommand: sharedConfig.paths.xcodebuildFormatterCommand,
            testingTimeout: testingTimeout
        )
        
        return try makeRunTestsTask(config: config)
    }
    
    public static func makeRunTestsTask(
        config: RunTestsTask.Config
    ) throws -> RunTestsTask {
        let builderConfig = Builder.Config(
            project: config.projectFile,
            scheme: config.scheme,
            derivedDataPath: config.derivedDataDir,
            logsPath: config.logsDir,
            configuration: "Debug", // TODO: hardcode
            xcodebuildFormatterCommand: config.xcodebuildFormatterCommand
        )
        
        let runnerConfig = TestsRunner.Config(
            builderConfig: builderConfig,
            projectDirPath: config.projectDir,
            testRunsDerivedDataPath: config.testRunsDerivedDataDir,
            testRunsLogsPath: config.logsDir,
            testPlan: config.testPlan,
            testWithoutBuilding: config.testWithoutBuilding,
            xcodebuildFormatterCommand: config.xcodebuildFormatterCommand,
            testingTimeout: config.testingTimeout
        )
        
        let logger: Logging = DependenciesFactory.resolve()
        let simulatorProvider: SimulatorProviding = DependenciesFactory.resolve()
        
        logger.important("Using scheme: \(config.scheme), testPlan: \(config.testPlan ?? "<nil>")")
        
        let iphone = try simulatorProvider.getAllDevices().first {
            $0.device.name == config.deviceModel && $0.runtime.version == config.osVersion
        }.unwrap(
            errorDescription: "Simulator \(config.deviceModel) with iOS \(config.osVersion) not found."
        )
        
        let builder = Builder(
            filesManager: DependenciesFactory.resolve(),
            logPathFactory: DependenciesFactory.resolve(),
            shell: DependenciesFactory.resolve(),
            logger: DependenciesFactory.resolve(),
            timeMeasurer: DependenciesFactory.resolve(),
            xcodebuildCommand: DependenciesFactory.resolve(),
            config: builderConfig
        )
        
        let testsRunner = TestsRunner(
            filesManager: DependenciesFactory.resolve(),
            xcTestService: DependenciesFactory.resolve(),
            logPathFactory: DependenciesFactory.resolve(),
            shell: DependenciesFactory.resolve(),
            config: runnerConfig,
            xcodebuildCommand: DependenciesFactory.resolve(),
            errorParser: DependenciesFactory.resolve()
        )
        
        let testRunPerformer: TestRunPerforming
        
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
            
            testRunPerformer = MultiScan(
                filesManager: DependenciesFactory.resolve(),
                logPathFactory: DependenciesFactory.resolve(),
                simulatorProvider: DependenciesFactory.resolve(),
                testPlanService: DependenciesFactory.resolve(),
                junitService: DependenciesFactory.resolve(),
                shell: DependenciesFactory.resolve(),
                logger: DependenciesFactory.resolve(),
                timeMeasurer: DependenciesFactory.resolve(),
                config: scanConfig,
                builder: builder,
                runner: testsRunner,
                projectDir: config.projectDir
            )
        } else {
            let scanConfig = Scan.Config(
                referenceSimulator: iphone,
                resultsDir: config.resultsDir,
                logsPath: config.logsDir,
                scheme: config.scheme,
                mergedXCResultPath: config.mergedXCResultPath,
                mergedJUnitPath: config.mergedJUnitPath
            )
            
            testRunPerformer = Scan(
                filesManager: DependenciesFactory.resolve(),
                logPathFactory: DependenciesFactory.resolve(),
                shell: DependenciesFactory.resolve(),
                logger: DependenciesFactory.resolve(),
                timeMeasurer: DependenciesFactory.resolve(),
                config: scanConfig,
                runner: testsRunner
            )
        }

        let task = RunTestsTask(
            logger: DependenciesFactory.resolve(),
            exitor: DependenciesFactory.resolve(),
            testRunPerformer: testRunPerformer
        )

        return task
    }

    public static func makeGuardianAfterBuildTask(
        projectDir: AbsolutePath,
        commandConfig: GuardianAfterBuildCommandConfig,
        sharedConfig: SharedConfigData,
        unitTestsExitCode: Int
    ) throws -> GuardianAfterBuildTask {
        let config = GuardianAfterBuildTask.Config(
            projectDir: projectDir,
            buildErrorsCheckerConfig: BuildErrorsChecker.Config(
                projectDir: projectDir,
                derivedDataPath: sharedConfig.paths.derivedDataDir,
                htmlReportOutputDir: sharedConfig.paths.xclogparserHTMLReportDir,
                jsonReportOutputFilePath: sharedConfig.paths.xclogparserJSONReport
            ),
            buildWarningsCheckerConfig: BuildWarningsChecker.Config(
                projectDir: projectDir,
                derivedDataPath: sharedConfig.paths.derivedDataDir,
                jsonReportOutputFilePath: sharedConfig.paths.xclogparserJSONReport,
                decodableConfig: commandConfig.buildWarningCheckerConfig
            ),
            unitTestsResultsCheckerConfig: .init(
                junitPath: sharedConfig.paths.mergedJUnit,
                projectDir: projectDir
            ),
            exitCodeCheckerConfig: .init(
                projectDir: projectDir,
                logsDir: sharedConfig.paths.logsDir
            ),
            changesCoverageLimitCheckerConfig: .init(
                decodableConfig: commandConfig.changesCoverageLimitCheckerConfig,
                projectDir: projectDir,
                excludedFileNameMatchers: commandConfig.targetsCoverageLimitCheckerConfig.defaultFilters
            ),
            targetsCoverageLimitCheckerConfig: .init(
                decodableConfig: commandConfig.targetsCoverageLimitCheckerConfig,
                projectDir: projectDir,
                xcresultDir: sharedConfig.paths.resultsDir,
                xccovTempCoverageFilePath: sharedConfig.paths.xccovFile
            )
        )

        let coverageCalculator = TargetCoverageCalculator(
            logger: DependenciesFactory.resolve(),
            config: TargetCoverageCalculator.Config(
                defaultFilters: commandConfig.targetsCoverageLimitCheckerConfig.defaultFilters,
                excludeFilesFilters: commandConfig.targetsCoverageLimitCheckerConfig.excludeFilesFilters,
                targetCoverageLimits: commandConfig.targetsCoverageLimitCheckerConfig.targetCoverageLimits,
                projectDir: projectDir
            )
        )

        let targetCoverageChecker = TargetsCoverageLimitChecker(
            logger: DependenciesFactory.resolve(),
            filesManager: DependenciesFactory.resolve(),
            shell: DependenciesFactory.resolve(),
            xccov: DependenciesFactory.resolve(),
            targetsFilterer: DependenciesFactory.resolve(),
            coverageCalculator: coverageCalculator,
            reporter: DependenciesFactory.resolve(),
            config: config.targetsCoverageLimitCheckerConfig
        )

        let changesCoverageChecker = ChangesCoverageLimitChecker(
            logger: DependenciesFactory.resolve(),
            gitlabCIEnvironmentReader: DependenciesFactory.resolve(.shared),
            git: DependenciesFactory.resolve(.shared),
            slather: DependenciesFactory.resolve(.shared),
            reporter: DependenciesFactory.resolve(.shared),
            config: config.changesCoverageLimitCheckerConfig
        )

        let buildErrorsChecker = BuildErrorsChecker(
            xclogparser: DependenciesFactory.resolve(.shared),
            reporter: DependenciesFactory.resolve(.shared),
            logger: DependenciesFactory.resolve(.shared),
            config: config.buildErrorsCheckerConfig
        )

        let buildWarningsChecker = BuildWarningsChecker(
            xclogparser: DependenciesFactory.resolve(.shared),
            reporter: BuildWarningsReporter(
                reporter: DependenciesFactory.resolve(.shared),
                issueFormatter: DependenciesFactory.resolve(.shared),
                failBuildWhenWarningsDetected: commandConfig.buildWarningCheckerConfig.failBuildWhenWarningsDetected
            ),
            logger: DependenciesFactory.resolve(.shared),
            config: config.buildWarningsCheckerConfig
        )

        let unitTestsChecker = UnitTestsResultsChecker(
            junitService: DependenciesFactory.resolve(.shared),
            gitlabCIEnvironmentReader: DependenciesFactory.resolve(.shared),
            reporter: DependenciesFactory.resolve(.shared),
            config: config.unitTestsResultsCheckerConfig
        )

        let exitCodeChecker = UnitTestsExitCodeChecker(
            checkerData: .init(unitTestsExitCode: unitTestsExitCode),
            environmentValueReader: DependenciesFactory.resolve(.shared),
            gitlabCIEnvironmentReader: DependenciesFactory.resolve(.shared),
            reporter: DependenciesFactory.resolve(.shared),
            filesManager: DependenciesFactory.resolve(.shared),
            config: config.exitCodeCheckerConfig
        )

        let task = GuardianAfterBuildTask(
            logger: DependenciesFactory.resolve(.shared),
            mergeRequestReporter: DependenciesFactory.resolve(.shared),
            targetCoverageChecker: targetCoverageChecker,
            changesCoverageChecker: changesCoverageChecker,
            buildErrorsChecker: buildErrorsChecker,
            buildWarningsChecker: buildWarningsChecker,
            unitTestsChecker: unitTestsChecker,
            exitCodeChecker: exitCodeChecker,
            config: config,
            environmentValueReader: DependenciesFactory.resolve(.shared)
        )

        return task
    }

    public static func makeCheckStopListTask(
        taskConfig: CheckStopListTask.Config
    ) throws -> CheckStopListTask {
        let task = CheckStopListTask(
            config: taskConfig,
            reporter: DependenciesFactory.resolve(.shared),
            filesChecker: DependenciesFactory.resolve(.shared),
            contentsChecker: DependenciesFactory.resolve(.shared)
        )

        return task
    }

    public static func makeBuildAppTask(
        builderConfig: Builder.Config,
        buildForTesting: Bool,
        buildDestination: BuildDestination
    ) -> BuildAppTask {
        let xcodebuildCommand: XcodebuildCommandProducing = DependenciesFactory.resolve()

        let builder = Builder(
            filesManager: DependenciesFactory.resolve(),
            logPathFactory: DependenciesFactory.resolve(),
            shell: DependenciesFactory.resolve(),
            logger: DependenciesFactory.resolve(),
            timeMeasurer: DependenciesFactory.resolve(),
            xcodebuildCommand: xcodebuildCommand,
            config: builderConfig
        )

        let buildTask = BuildAppTask(
            builder: builder,
            buildForTesting: buildForTesting,
            destination: buildDestination
        )

        return buildTask
    }

    public static func makeArchiveAndExportIPATask(
        taskConfig: ArchiveAndExportIPATaskConfig
    ) -> ArchiveAndExportIPATask {
        let builderConfig = Builder.Config(
            project: taskConfig.projectFile,
            scheme: taskConfig.scheme,
            derivedDataPath: taskConfig.derivedDataDir,
            logsPath: taskConfig.logsDir,
            configuration: taskConfig.buildConfiguration,
            xcodebuildFormatterCommand: taskConfig.xcodebuildFormatterCommand
        )
        
        let builder = Builder(
            filesManager: DependenciesFactory.resolve(),
            logPathFactory: DependenciesFactory.resolve(),
            shell: DependenciesFactory.resolve(),
            logger: DependenciesFactory.resolve(),
            timeMeasurer: DependenciesFactory.resolve(),
            xcodebuildCommand: DependenciesFactory.resolve(),
            config: builderConfig
        )
        
        let task = ArchiveAndExportIPATask(
            simulatorProvider: DependenciesFactory.resolve(),
            archiveProcessor: DependenciesFactory.resolve(),
            xcodeProjectPatcher: DependenciesFactory.resolve(),
            dsymsExtractor: DependenciesFactory.resolve(),
            provisioningProfilesService: DependenciesFactory.resolve(),
            builder: builder,
            config: taskConfig
        )

        return task
    }

    public static func makeSetProvisioningTask(
        taskConfig: SetProvisioningTaskConfig
    ) -> SetProvisioningTask {
        let task = SetProvisioningTask(
            provisioningProfileService: DependenciesFactory.resolve(),
            projectPatcher: DependenciesFactory.resolve(),
            config: taskConfig
        )

        return task
    }

    public static func makeCertsInstallTask(
        taskConfig: CertsInstallConfig
    ) -> CertsInstallTask {
        let task = CertsInstallTask(
            logger: DependenciesFactory.resolve(),
            shell: DependenciesFactory.resolve(),
            installer: DependenciesFactory.resolve(),
            config: taskConfig
        )

        return task
    }

    public static func makeAddJiraIssueCommentTask(
        taskConfig: AddJiraIssueCommentTask.Config
    ) -> AddJiraIssueCommentTask {
        let task = AddJiraIssueCommentTask(
            logger: DependenciesFactory.resolve(),
            jiraClient: DependenciesFactory.resolve(),
            issueKeySearcher: DependenciesFactory.resolve(),
            config: taskConfig
        )

        return task
    }

    public static func makeCertsChangePasswordTask(
        config: CertsChangePasswordTaskConfig
    ) throws -> CertsChangePasswordTask {
        let task = CertsChangePasswordTask(
            logger: DependenciesFactory.resolve(),
            shell: DependenciesFactory.resolve(),
            repo: DependenciesFactory.resolve(),
            passwordReader: DependenciesFactory.resolve(),
            filesManager: DependenciesFactory.resolve(),
            config: config
        )

        return task
    }

    public static func makeCertsUpdateTask(
        authKeyPath: AbsolutePath,
        authKeyIssuerID: SensitiveData<String>,
        taskConfig: CertsUpdateConfig
    ) throws -> CertsUpdateTask {
        let keyIdParser: AppStoreConnectAuthKeyIDParsing = DependenciesFactory.resolve()

        let authKeyID = try keyIdParser.apiKeyID(from: authKeyPath)

        let client = try AppStoreConnectAPIClient(
            keyId: authKeyID,
            issuerId: authKeyIssuerID.sensitiveValue,
            privateKeyPath: authKeyPath.string
        )

        let certsService = CertsUpdater(
            logger: DependenciesFactory.resolve(),
            repo: CertsRepository(
                git: DependenciesFactory.resolve(),
                openssl: DependenciesFactory.resolve(),
                filesManager: DependenciesFactory.resolve(),
                provisioningProfileService: DependenciesFactory.resolve(),
                provisionProfileParser: DependenciesFactory.resolve(),
                security: DependenciesFactory.resolve(),
                logger: DependenciesFactory.resolve(),
                config: DependenciesFactory.resolve()
            ),
            generator: CertsGenerator(
                logger: DependenciesFactory.resolve(),
                openssl: DependenciesFactory.resolve(),
                api: client
            ),
            filesManager: DependenciesFactory.resolve()
        )

        let task = CertsUpdateTask(
            logger: DependenciesFactory.resolve(),
            shell: DependenciesFactory.resolve(),
            certsService: certsService,
            config: taskConfig
        )

        return task
    }

    public static func makeChangeJiraIssueLabelsTask(
        taskConfig: ChangeJiraIssueLabelsTask.Config
    ) throws -> ChangeJiraIssueLabelsTask {
        let task = ChangeJiraIssueLabelsTask(
            logger: DependenciesFactory.resolve(),
            jiraClient: DependenciesFactory.resolve(),
            issueKeySearcher: DependenciesFactory.resolve(),
            config: taskConfig
        )

        return task
    }

    public static func makeChangeVersionTask(
        versioningConfig: ProjectVersioningService.Config,
        taskConfig: ChangeVersionTask.Config
    ) throws -> ChangeVersionTask {
        let versioningService = ProjectVersioningService(
            logger: DependenciesFactory.resolve(),
            filesManager: DependenciesFactory.resolve(),
            versionConverter: DependenciesFactory.resolve(),
            projectPatcher: DependenciesFactory.resolve(),
            git: DependenciesFactory.resolve(),
            config: versioningConfig
        )

        let task = ChangeVersionTask(
            logger: DependenciesFactory.resolve(),
            versioningService: versioningService,
            config: taskConfig
        )

        return task
    }

    public static func makeCheckCommitsTask(
        checkerConfig: CommitsChecker.Config
    ) throws -> CheckCommitsTask {
        let checker = CommitsChecker(
            logger: DependenciesFactory.resolve(),
            git: DependenciesFactory.resolve(),
            gitlabCIEnvironment: DependenciesFactory.resolve(),
            reporter: DependenciesFactory.resolve(),
            config: checkerConfig
        )

        let task = CheckCommitsTask(
            checker: checker,
            reporter: DependenciesFactory.resolve()
        )

        return task
    }

    public static func makeGuardianBeforeBuildTask(
        projectDir: AbsolutePath,
        expiringToDoBlockingConfig: ExpiringToDoBlockingConfig,
        commandConfig: GuardianBeforeBuildCommandConfig,
        sharedConfig: SharedConfigData
    ) throws -> GuardianBeforeBuildTask {
        let warningsStorageConfig = WarningsStorage.Config(
            projectDir: projectDir,
            warningsJsonsFolder: sharedConfig.paths.warningsJsonsDir
        )

        let warningsStorage = WarningsStorage(
            filesManager: DependenciesFactory.resolve(),
            config: warningsStorageConfig
        )

        // MARK: Warning limits

        let warningLimitsChecker = WarningLimitsChecker(
            swiftLint: DependenciesFactory.resolve(),
            filesManager: DependenciesFactory.resolve(),
            warningsStorage: warningsStorage,
            logger: DependenciesFactory.resolve(),
            git: DependenciesFactory.resolve(),
            reporter: DependenciesFactory.resolve(),
            gitlabCIEnvironmentReader: DependenciesFactory.resolve()
        )

        let warningLimitsUntrackedChecker = WarningLimitsUntrackedChecker(
            swiftLint: DependenciesFactory.resolve(),
            filesManager: DependenciesFactory.resolve(),
            warningsStorage: warningsStorage,
            logger: DependenciesFactory.resolve(),
            git: DependenciesFactory.resolve(),
            reporter: DependenciesFactory.resolve(),
            slather: DependenciesFactory.resolve(),
            gitlabCIEnvironmentReader: DependenciesFactory.resolve()
        )

        // MARK: TODOs

        let expiringToDoReporter = ExpiringToDoReporter(
            reporter: DependenciesFactory.resolve(),
            todosSorter: DependenciesFactory.resolve(),
            failIfExpiredDetected: commandConfig.expiringTODOs.failIfExpiredDetected,
            needFail: commandConfig.expiringTODOs.needFail
        )

        let responsibilityProvider = ExpiringToDoResponsibilityProvider(config: expiringToDoBlockingConfig)

        let expiringToDoVerifier = ExpiringToDoVerifier(
            dateFormat: commandConfig.expiringTODOs.todoDateFormat,
            warningAfterDaysLeft: commandConfig.expiringTODOs.warningAfterDaysLeft,
            responsibilityProvider: responsibilityProvider
        )

        let expiringToDoConfig = ExpiringToDoConfig(
            enabled: commandConfig.expiringTODOs.enabled,
            projectDir: projectDir,
            excludeFilesPaths: commandConfig.expiringTODOs.excludeFilesPaths,
            excludeFilesNames: commandConfig.expiringTODOs.excludeFilesNames,
            maxFutureDays: commandConfig.expiringTODOs.maxFutureDays,
            ignoreCheckForSourceBranches: commandConfig.expiringTODOs.ignoreCheckForSourceBranches,
            ignoreCheckForTargetBranches: commandConfig.expiringTODOs.ignoreCheckForTargetBranches,
            gitlabGroupIDToFetchMembersFrom: commandConfig.expiringTODOs.gitlabGroupIDToFetchMembersFrom
        )

        let expiredToDoChecker = ExpiringToDoChecker(
            filesManager: DependenciesFactory.resolve(),
            reporter: expiringToDoReporter,
            expiringToDoParser: DependenciesFactory.resolve(),
            expiringToDoVerifier: expiringToDoVerifier,
            gitlabCIEnvironmentReader: DependenciesFactory.resolve(),
            gitlabApi: DependenciesFactory.resolve(),
            logger: DependenciesFactory.resolve(),
            config: expiringToDoConfig
        )

        // MARK: Stubs

        let stubDeclarationConfig = StubDeclarationConfig(
            enabled: commandConfig.stubsDeclarations.enabled,
            fail: commandConfig.stubsDeclarations.fail,
            projectDir: projectDir,
            mocksTargetsPath: try NSRegularExpression(
                pattern: commandConfig.stubsDeclarations.mocksTargetsPath,
                options: [.anchorsMatchLines]
            ),
            testsTargetsPath: try NSRegularExpression(
                pattern: commandConfig.stubsDeclarations.testsTargetsPath,
                options: [.anchorsMatchLines]
            ),
            ignoredFiles: commandConfig.stubsDeclarations.ignoredFiles
        )

        let stubDeclarationChecker = StubDeclarationChecker(
            logger: DependenciesFactory.resolve(),
            filesManager: DependenciesFactory.resolve(),
            slatherService: DependenciesFactory.resolve(),
            reporter: StubDeclarationReporter(
                reporter: DependenciesFactory.resolve(),
                config: stubDeclarationConfig
            ),
            codeParser: DependenciesFactory.resolve(),
            config: stubDeclarationConfig
        )

        // MARK: Files paths

        let filePathChecker = AllowedFilePathChecker(
            logger: DependenciesFactory.resolve(),
            reporter: DependenciesFactory.resolve(),
            gitlabClient: DependenciesFactory.resolve(),
            gitlabCIEnvironmentReader: DependenciesFactory.resolve(),
            config: AllowedFilePathConfig(
                allowedFilePath: commandConfig.filesNamingConfig.allowedFilePath
            )
        )

        // MARK: Task

        let task = GuardianBeforeBuildTask(
            logger: DependenciesFactory.resolve(),
            mergeRequestReporter: DependenciesFactory.resolve(),
            warningLimitsChecker: warningLimitsChecker,
            warningLimitsUntrackedChecker: warningLimitsUntrackedChecker,
            expiredToDoChecker: expiredToDoChecker,
            stubDeclarationChecker: stubDeclarationChecker,
            filePathChecker: filePathChecker,
            config: GuardianBeforeBuildTask.WarningLimitsConfig(
                projectDir: projectDir,
                jiraTaskRegex: sharedConfig.values.jiraProjectKey + "-\\d+",
                swiftlintConfigPath: sharedConfig.paths.swiftlintConfig,
                loweringWarningLimitsCommitMessage: commandConfig.loweringWarningLimitsCommitMessage,
                trackingNewFoldersCommitMessage: commandConfig.trackingNewFoldersCommitMessage,
                remoteName: commandConfig.trackingPushRemoteName,
                committeeName: sharedConfig.values.gitAuthorName,
                committeeEmail: sharedConfig.values.gitAuthorEmail,
                warningsStorageConfig: warningsStorageConfig
            ),
            gitlabCIEnvironmentReader: DependenciesFactory.resolve()
        )

        return task
    }

    public static func makeGuardianCheckAuthorTask(
        commandConfig: GuardianCheckAuthorCommandConfig
    ) throws -> GuardianCheckAuthorTask {
        let mergeRequestAuthorChecker = MergeRequestAuthorChecker(
            reporter: DependenciesFactory.resolve(),
            gitlabApi: DependenciesFactory.resolve(),
            gitlabCIEnvironment: DependenciesFactory.resolve(),
            validGitLabUserName: commandConfig.validGitLabUserName,
            validCommitAuthorName: commandConfig.validCommitAuthorName
        )

        let task = GuardianCheckAuthorTask(
            logger: DependenciesFactory.resolve(),
            mergeRequestReporter: DependenciesFactory.resolve(),
            mergeRequestAuthorChecker: mergeRequestAuthorChecker,
            gitlabCIEnvironmentReader: DependenciesFactory.resolve()
        )

        return task
    }

    public static func makeGuardianInitialNoteTask(
    ) throws -> GuardianInitialNoteTask {
        let task = GuardianInitialNoteTask(
            logger: DependenciesFactory.resolve(),
            mergeRequestReporter: DependenciesFactory.resolve(),
            gitlabCIEnvironmentReader: DependenciesFactory.resolve()
        )

        return task
    }

    public static func makeMeasureBuildTimeTask(
        builderConfig: Builder.Config,
        config: MeasureBuildTimeTask.Config
    ) throws -> MeasureBuildTimeTask {
        let builder = Builder(
            filesManager: DependenciesFactory.resolve(),
            logPathFactory: DependenciesFactory.resolve(),
            shell: DependenciesFactory.resolve(),
            logger: DependenciesFactory.resolve(),
            timeMeasurer: DependenciesFactory.resolve(),
            xcodebuildCommand: DependenciesFactory.resolve(),
            config: builderConfig
        )

        let task = MeasureBuildTimeTask(
            simulatorProvider: DependenciesFactory.resolve(),
            logger: DependenciesFactory.resolve(),
            shell: DependenciesFactory.resolve(),
            logPathFactory: DependenciesFactory.resolve(),
            builder: builder,
            config: config
        )

        return task
    }

    public static func makePatchTestPlanEnvTask(
        config: PatchTestPlanEnvTaskConfig
    ) throws -> PatchTestPlanEnvTask {
        let task = PatchTestPlanEnvTask(
            logger: DependenciesFactory.resolve(),
            filesManager: DependenciesFactory.resolve(),
            environmentReader: DependenciesFactory.resolve(),
            patcher: DependenciesFactory.resolve(),
            config: config
        )

        return task
    }

    public static func makeReportUnusedCodeTask(
        taskConfig: ReportUnusedCodeTaskConfig,
        mattermostApiURL: URL?,
        paths: PathsFactoring
    ) throws -> ReportUnusedCodeTask {
        let mattermostAPIClient = mattermostApiURL.map {
            MattermostAPIClient(
                baseURL: $0,
                logger: DependenciesFactory.resolve()
            )
        }

        let task = ReportUnusedCodeTask(
            logger: DependenciesFactory.resolve(),
            shell: DependenciesFactory.resolve(),
            filesManager: DependenciesFactory.resolve(),
            peripheryService: DependenciesFactory.resolve(),
            resultsFormatter: DependenciesFactory.resolve(),
            paths: paths,
            gitlabCIEnvironment: DependenciesFactory.resolve(),
            mattermostAPIClient: mattermostAPIClient,
            config: taskConfig
        )

        return task
    }

    public static func makeUploadGitLabPackageTask(
        taskConfig: UploadGitLabPackageTask.Config
    ) throws -> UploadGitLabPackageTask {
        let task = UploadGitLabPackageTask(
            logger: DependenciesFactory.resolve(),
            progressLogger: DependenciesFactory.resolve(),
            filesManager: DependenciesFactory.resolve(),
            gitlabApi: DependenciesFactory.resolve(),
            timeMeasurer: DependenciesFactory.resolve(),
            config: taskConfig
        )

        return task
    }

    public static func makeUploadToAppStoreTask(
        authKeyPath: AbsolutePath,
        authKeyIssuerID: SensitiveData<String>,
        paths: PathsFactoring
    ) throws -> UploadToAppStoreTask {
        let ipaUploader = AppStoreConnectIPAUploader(
            logger: DependenciesFactory.resolve(),
            filesManager: DependenciesFactory.resolve(),
            shell: DependenciesFactory.resolve(),
            tokenGenerator: try AppStoreConnectTokenGenerator(
                filesManager: DependenciesFactory.resolve(),
                authKeyIDParser: DependenciesFactory.resolve(),
                jwtGenerator: AppStoreConnectJWTGenerator(),
                authKeyPath: authKeyPath,
                authKeyIssuerID: authKeyIssuerID.sensitiveValue
            ),
            authKeyIDParser: DependenciesFactory.resolve(),
            config: .init(
                authKeyPath: authKeyPath,
                authKeyIssuerID: authKeyIssuerID.sensitiveValue,
                logDir: try paths.logsDir.appending(
                    path: "upload-to-appstore"
                )
            )
        )

        let task = UploadToAppStoreTask(uploader: ipaUploader)

        return task
    }
}
