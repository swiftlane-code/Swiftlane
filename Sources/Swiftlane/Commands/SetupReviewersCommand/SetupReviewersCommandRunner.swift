
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
        sharedConfig _: SharedConfigData
    ) throws {
        let environmentValueReader: EnvironmentValueReading = DependenciesFactory.resolve()
        let filesManager: FSManaging = DependenciesFactory.resolve()

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
            logger: DependenciesFactory.resolve(),
            config: taskConfig,
            gitlabCIEnvironment: DependenciesFactory.resolve(),
            gitlabApi: DependenciesFactory.resolve()
        )

        try task.run()
    }
}
