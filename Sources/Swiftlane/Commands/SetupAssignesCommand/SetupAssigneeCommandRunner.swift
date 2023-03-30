
import Foundation
import GitLabAPI
import Guardian
import Simulator
import SwiftlaneCore
import Yams

public struct SetupAssigneeCommandConfig: Decodable {}

public struct SetupAssigneeCommandRunner: CommandRunnerProtocol {
    private func makeGitLabAPIClient(logger: Logging) throws -> GitLabAPIClientProtocol {
        try GitLabAPIClient(logger: logger)
    }

    public func verifyConfigs(
        params _: SetupAssigneeCommandParamsAccessing,
        commandConfig _: SetupAssigneeCommandConfig,
        sharedConfig _: SharedConfigData,
        logger: Logging
    ) throws -> Bool {
        _ = try makeGitLabAPIClient(logger: logger)
        return true
    }

    public func run(
        params _: SetupAssigneeCommandParamsAccessing,
        commandConfig _: SetupAssigneeCommandConfig,
        sharedConfig: SharedConfigData,
        logger: Logging
    ) throws {
        let environmentValueReader = EnvironmentValueReader()
        let gitlabCIEnvironmentReader = GitLabCIEnvironmentReader(environmentValueReading: environmentValueReader)

        let taskConfig = SetupAssigneeTask.Config()

        let task = SetupAssigneeTask(
            logger: logger,
            config: taskConfig,
            gitlabCIEnvironment: gitlabCIEnvironmentReader,
            gitlabApi: try makeGitLabAPIClient(logger: logger)
        )

        let projectPath = try gitlabCIEnvironmentReader.string(.CI_PROJECT_PATH)
        guard sharedConfig.values.availableProjects.isMatching(string: projectPath) else {
            logger.warn("Skipped run task about project with path \(projectPath.quoted)")
            return
        }

        try task.run()
    }
}
