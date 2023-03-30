
import Foundation
import GitLabAPI
import Guardian
import Simulator
import SwiftlaneCore
import Yams

public struct SetupReviewersCommandConfig: Decodable {
    public let reviewersConfigPath: String
    public let gitlabGroupIDToFetchMembersFrom: Int?
}

public struct SetupReviewersCommandRunner: CommandRunnerProtocol {
    public func run(
        params _: SetupReviewersCommandParamsAccessing,
        commandConfig: SetupReviewersCommandConfig,
        sharedConfig: SharedConfigData,
        logger: Logging
    ) throws {
        let environmentValueReader = EnvironmentValueReader()
        let gitlabCIEnvironmentReader = GitLabCIEnvironmentReader(environmentValueReading: environmentValueReader)

        let filesManager = FSManager(logger: logger, fileManager: FileManager.default)

        let expandedReviewersConfigPath = try environmentValueReader.expandVariables(
            in: commandConfig.reviewersConfigPath
        )

        let reviewersConfig: SetupReviewersTask.ReviewersConfig = try filesManager.decode(
            try AbsolutePath(expandedReviewersConfigPath),
            decoder: YAMLDecoder()
        )

        let gitlabGroupIDToFetchMembersFrom = try commandConfig.gitlabGroupIDToFetchMembersFrom ??
            environmentValueReader.int(ShellEnvKey.GITLAB_GROUP_DEV_TEAM_ID_TO_FETCH_MEMBERS)

        let taskConfig = SetupReviewersTask.Config(
            reviewersConfig: reviewersConfig,
            gitlabGroupID: gitlabGroupIDToFetchMembersFrom
        )

        let task = SetupReviewersTask(
            logger: logger,
            config: taskConfig,
            gitlabCIEnvironment: gitlabCIEnvironmentReader,
            gitlabApi: try GitLabAPIClient(logger: logger)
        )

        let projectPath = try gitlabCIEnvironmentReader.string(.CI_PROJECT_PATH)
        guard sharedConfig.values.availableProjects.isMatching(string: projectPath) else {
            logger.warn("Skipped run task about project with path \(projectPath.quoted)")
            return
        }

        try task.run()
    }
}
