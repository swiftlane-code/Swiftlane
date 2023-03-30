
import Foundation
import GitLabAPI
import Guardian
import Simulator
import SwiftlaneCore
import Yams

public struct SetupLabelsCommandConfig: Decodable {
    public let labelsConfigPath: String
}

public struct SetupLabelsCommandRunner: CommandRunnerProtocol {
    public func verifyConfigs(
        params _: SetupLabelsCommandParamsAccessing,
        commandConfig _: SetupLabelsCommandConfig,
        sharedConfig _: SharedConfigData,
        logger: Logging
    ) throws -> Bool {
        let _ = try GitLabAPIClient(logger: logger)
        return true
    }

    public func run(
        params _: SetupLabelsCommandParamsAccessing,
        commandConfig: SetupLabelsCommandConfig,
        sharedConfig: SharedConfigData,
        logger: Logging
    ) throws {
        let environmentValueReader = EnvironmentValueReader()
        let gitlabCIEnvironmentReader = GitLabCIEnvironmentReader(environmentValueReading: environmentValueReader)

        let filesManager = FSManager(logger: logger, fileManager: FileManager.default)

        let expandedLabelsConfigPath = try environmentValueReader.expandVariables(
            in: commandConfig.labelsConfigPath
        )

        let labelsConfig: SetupLabelsTask.LabelsConfig = try filesManager.decode(
            try AbsolutePath(expandedLabelsConfigPath),
            decoder: YAMLDecoder()
        )

        let taskConfig = SetupLabelsTask.Config(
            labelsConfig: labelsConfig
        )

        let task = SetupLabelsTask(
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
