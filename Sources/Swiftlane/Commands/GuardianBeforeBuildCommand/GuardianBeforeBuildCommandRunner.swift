//

import Foundation
import Git
import GitLabAPI
import Guardian
import SwiftlaneCore
import Yams

public struct GuardianBeforeBuildCommandRunner: CommandRunnerProtocol {
    public func verifyConfigs(
        params _: GuardianBeforeBuildCommandParamsAccessing,
        commandConfig _: GuardianBeforeBuildCommandConfig,
        sharedConfig _: SharedConfigData,
        logger: Logging
    ) throws -> Bool {
        let _ = try GitLabAPIClient(logger: logger)
        return true
    }

    public func run(
        params: GuardianBeforeBuildCommandParamsAccessing,
        commandConfig: GuardianBeforeBuildCommandConfig,
        sharedConfig: SharedConfigData,
        logger: Logging
    ) throws {
        let filesManager = FSManager(
            logger: logger,
            fileManager: FileManager.default
        )

        let sigIntHandler = SigIntHandler(logger: logger)
        let xcodeChecker = XcodeChecker()
        let shell = ShellExecutor(
            sigIntHandler: sigIntHandler,
            logger: logger,
            xcodeChecker: xcodeChecker,
            filesManager: filesManager
        )

        let environmentValueReader = EnvironmentValueReader()

        let gitlabCIEnvironmentReader = GitLabCIEnvironmentReader(
            environmentValueReading: environmentValueReader
        )

        let gitlabApiClient = try GitLabAPIClient(logger: logger)

        let mergeRequestReporter = MergeRequestReporter(
            logger: logger,
            gitlabApi: gitlabApiClient,
            gitlabCIEnvironment: gitlabCIEnvironmentReader,
            reportFactory: MergeRequestReportFactory(),
            publishEmptyReport: true,
            commentIdentificator: "guardian-before-build"
        )

        let swiftLint = SwiftLint(shell: shell, swiftlintPath: "swiftlint")

        let warningsStorageConfig = WarningsStorage.Config(
            projectDir: params.sharedConfigOptions.projectDir,
            warningsJsonsFolder: sharedConfig.paths.warningsJsonsDir
        )

        let warningsStorage = WarningsStorage(
            filesManager: filesManager,
            config: warningsStorageConfig
        )

        let git = Git(
            shell: shell,
            filesManager: filesManager,
            diffParser: GitDiffParser(logger: logger)
        )

        // MARK: Warning limits

        let warningLimitsCheckerReporter = WarnigLimitsCheckerRussianReporter(
            reporter: mergeRequestReporter
        )

        let warningLimitsChecker = WarningLimitsChecker(
            swiftLint: swiftLint,
            filesManager: filesManager,
            warningsStorage: warningsStorage,
            logger: logger,
            git: git,
            reporter: warningLimitsCheckerReporter,
            gitlabCIEnvironmentReader: gitlabCIEnvironmentReader
        )

        let warningLimitsUntrackedChecker = WarningLimitsUntrackedChecker(
            swiftLint: swiftLint,
            filesManager: filesManager,
            warningsStorage: warningsStorage,
            logger: logger,
            git: git,
            reporter: warningLimitsCheckerReporter,
            slather: SlatherService(filesManager: filesManager),
            gitlabCIEnvironmentReader: gitlabCIEnvironmentReader
        )

        // MARK: TODOs

        let expiringToDoReporter = ExpiringToDoReporter(
            reporter: mergeRequestReporter,
            todosSorter: ExpiringToDoSorter(),
            failIfExpiredDetected: commandConfig.expiringTODOs.failIfExpiredDetected,
            needFail: commandConfig.expiringTODOs.needFail
        )

        let expandedBlockingConfigPath = try environmentValueReader.expandVariables(
            in: commandConfig.expiringTODOs.blockingConfigPath
        )

        let expiringToDoBlockingConfig: ExpiringToDoBlockingConfig = try filesManager.decode(
            try AbsolutePath(expandedBlockingConfigPath),
            decoder: YAMLDecoder()
        )

        let responsibilityProvider = ExpiringToDoResponsibilityProvider(config: expiringToDoBlockingConfig)

        let expiringToDoVerifier = ExpiringToDoVerifier(
            dateFormat: commandConfig.expiringTODOs.todoDateFormat,
            warningAfterDaysLeft: commandConfig.expiringTODOs.warningAfterDaysLeft,
            responsibilityProvider: responsibilityProvider
        )

        let expiringToDoParser = ExpiringToDoParser()

        let expiredToDoChecker = ExpiringToDoChecker(
            filesManager: filesManager,
            reporter: expiringToDoReporter,
            expiringToDoParser: expiringToDoParser,
            expiringToDoVerifier: expiringToDoVerifier,
            gitlabCIEnvironmentReader: gitlabCIEnvironmentReader,
            gitlabApi: gitlabApiClient,
            logger: logger,
            config: ExpiringToDoConfig(
                enabled: commandConfig.expiringTODOs.enabled,
                projectDir: params.sharedConfigOptions.projectDir,
                excludeFilesPaths: commandConfig.expiringTODOs.excludeFilesPaths,
                excludeFilesNames: commandConfig.expiringTODOs.excludeFilesNames,
                maxFutureDays: commandConfig.expiringTODOs.maxFutureDays,
                ignoreCheckForSourceBranches: commandConfig.expiringTODOs.ignoreCheckForSourceBranches,
                ignoreCheckForTargetBranches: commandConfig.expiringTODOs.ignoreCheckForTargetBranches,
                gitlabGroupIDToFetchMembersFrom: commandConfig.expiringTODOs.gitlabGroupIDToFetchMembersFrom
            )
        )

        // MARK: Stubs

        let stubDeclarationConfig = StubDeclarationConfig(
            enabled: commandConfig.stubsDeclarations.enabled,
            fail: commandConfig.stubsDeclarations.fail,
            projectDir: params.sharedConfigOptions.projectDir,
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
            logger: logger,
            filesManager: filesManager,
            slatherService: SlatherService(filesManager: filesManager),
            reporter: StubDeclarationReporter(reporter: mergeRequestReporter, config: stubDeclarationConfig),
            codeParser: try SwiftCodeParser(logger: logger, filesManager: filesManager),
            config: stubDeclarationConfig
        )

        // MARK: Files paths

        let filePathChecker = AllowedFilePathChecker(
            logger: logger,
            reporter: FilePathReporter(reporter: mergeRequestReporter),
            gitlabClient: gitlabApiClient,
            gitlabCIEnvironmentReader: gitlabCIEnvironmentReader,
            config: AllowedFilePathConfig(
                allowedFilePath: commandConfig.filesNamingConfig.allowedFilePath
            )
        )

        // MARK: Task

        let task = GuardianBeforeBuildTask(
            logger: logger,
            mergeRequestReporter: mergeRequestReporter,
            warningLimitsChecker: warningLimitsChecker,
            warningLimitsUntrackedChecker: warningLimitsUntrackedChecker,
            expiredToDoChecker: expiredToDoChecker,
            stubDeclarationChecker: stubDeclarationChecker,
            filePathChecker: filePathChecker,
            config: GuardianBeforeBuildTask.WarningLimitsConfig(
                projectDir: params.sharedConfigOptions.projectDir,
                jiraTaskRegex: sharedConfig.values.jiraProjectKey + "-\\d+",
                swiftlintConfigPath: sharedConfig.paths.swiftlintConfig,
                loweringWarningLimitsCommitMessage: commandConfig.loweringWarningLimitsCommitMessage,
                trackingNewFoldersCommitMessage: commandConfig.trackingNewFoldersCommitMessage,
                remoteName: commandConfig.trackingPushRemoteName,
                committeeName: sharedConfig.values.gitAuthorName,
                committeeEmail: sharedConfig.values.gitAuthorEmail,
                warningsStorageConfig: warningsStorageConfig
            ),
            gitlabCIEnvironmentReader: gitlabCIEnvironmentReader
        )

        try task.run()
    }
}
