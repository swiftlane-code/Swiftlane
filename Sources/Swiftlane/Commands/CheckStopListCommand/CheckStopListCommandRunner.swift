
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
        return true
    }

    public func run(
        params: CheckStopListCommandParamsAccessing,
        commandConfig: CheckStopListCommandConfig,
        sharedConfig _: SharedConfigData,
        logger _: Logging
    ) throws {
        let environmentValueReader: EnvironmentValueReading = DependenciesFactory.resolve()
        let filesManager: FSManaging = DependenciesFactory.resolve()

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

        let task = try TasksFactory.makeCheckStopListTask(
            taskConfig: taskConfig
        )

        try task.run(
            projectDir: params.sharedConfigOptions.projectDir
        )
    }
}
