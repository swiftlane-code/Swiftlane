
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
    public func run(
        params _: SetupLabelsCommandParamsAccessing,
        commandConfig: SetupLabelsCommandConfig,
        sharedConfig _: SharedConfigData
    ) throws {
        let environmentValueReader: EnvironmentValueReading = DependenciesFactory.resolve()

        let filesManager: FSManaging = DependenciesFactory.resolve()

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
            logger: DependenciesFactory.resolve(),
            config: taskConfig,
            gitlabCIEnvironment: DependenciesFactory.resolve(),
            gitlabApi: DependenciesFactory.resolve()
        )

        try task.run()
    }
}
