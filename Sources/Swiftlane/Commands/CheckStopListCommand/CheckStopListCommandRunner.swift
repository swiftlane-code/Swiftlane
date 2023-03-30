
import Foundation
import Git
import GitLabAPI
import Guardian
import Simulator
import SwiftlaneCore
import Yams

public struct CheckStopListCommandConfig: Decodable {
    public let stopListConfigPath: String
    public let excludingUsers: [StringMatcher]
}

public struct CheckStopListCommandRunner: CommandRunnerProtocol {
    public func verifyConfigs(
        params _: CheckStopListCommandParamsAccessing,
        commandConfig _: CheckStopListCommandConfig,
        sharedConfig _: SharedConfigData,
        logger: Logging
    ) throws -> Bool {
        let _ = try GitLabAPIClient(logger: logger)
        return true
    }

    public func run(
        params: CheckStopListCommandParamsAccessing,
        commandConfig: CheckStopListCommandConfig,
        sharedConfig: SharedConfigData,
        logger: Logging
    ) throws {
        let environmentValueReader = EnvironmentValueReader()
        let gitlabCIEnvironmentReader = GitLabCIEnvironmentReader(environmentValueReading: environmentValueReader)

        let sigIntHandler = SigIntHandler(logger: logger)

        let xcodeChecker = XcodeChecker()

        let filesManager = FSManager(logger: logger, fileManager: FileManager.default)

        let shell: ShellExecuting = ShellExecutor(
            sigIntHandler: sigIntHandler,
            logger: logger,
            xcodeChecker: xcodeChecker,
            filesManager: filesManager
        )

        let git = Git(
            shell: shell,
            filesManager: filesManager,
            diffParser: GitDiffParser(logger: logger)
        )

        let expandedStopListConfigPath = try environmentValueReader.expandVariables(
            in: commandConfig.stopListConfigPath
        )

        let stopListConfig: CheckStopListTask.StopListConfig = try filesManager.decode(
            try AbsolutePath(expandedStopListConfigPath),
            decoder: YAMLDecoder()
        )

        let taskConfig = CheckStopListTask.Config(
            stopListConfig: stopListConfig
        )

        let mergeRequestReporter = MergeRequestReporter(
            logger: logger,
            gitlabApi: try GitLabAPIClient(logger: logger),
            gitlabCIEnvironment: gitlabCIEnvironmentReader,
            reportFactory: MergeRequestReportFactory(),
            publishEmptyReport: true
        )

        let filesReporter = FilesCheckerEnReporter(
            reporter: mergeRequestReporter
        )

        let filesChecker = FilesChecker(
            logger: logger,
            gitlabCIEnvironment: gitlabCIEnvironmentReader,
            gitlabApi: try GitLabAPIClient(logger: logger),
            reporter: filesReporter
        )

        let contentsReporter = ContentCheckerEnReporter(
            reporter: mergeRequestReporter,
            rangesWelder: RangesWelder()
        )

        let contentsChecker = ContentChecker(
            logger: logger,
            filesManager: filesManager,
            git: git,
            reporter: contentsReporter
        )

        let task = CheckStopListTask(
            config: taskConfig,
            reporter: mergeRequestReporter,
            filesChecker: filesChecker,
            contentsChecker: contentsChecker
        )

        let projectPath = try gitlabCIEnvironmentReader.string(.CI_PROJECT_PATH)
        guard sharedConfig.values.availableProjects.isMatching(string: projectPath) else {
            logger.warn("Skipped run task about project with path \(projectPath.quoted)")
            return
        }

        let piplineTriggerUser = try gitlabCIEnvironmentReader.string(.GITLAB_USER_LOGIN)
        guard !commandConfig.excludingUsers.isMatching(string: piplineTriggerUser) else {
            logger.warn("Skipped run task because the user \(piplineTriggerUser.quoted) can do everything")
            return
        }

        try task.run(
            projectDir: params.sharedConfigOptions.projectDir
        )
    }
}
