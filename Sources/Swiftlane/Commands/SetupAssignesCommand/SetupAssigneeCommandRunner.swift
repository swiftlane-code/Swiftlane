
import Foundation
import GitLabAPI
import Guardian
import Simulator
import SwiftlaneCore
import Yams

public struct SetupAssigneeCommandConfig: Decodable {}

public struct SetupAssigneeCommandRunner: CommandRunnerProtocol {
    public func run(
        params _: SetupAssigneeCommandParamsAccessing,
        commandConfig _: SetupAssigneeCommandConfig,
        sharedConfig: SharedConfigData
    ) throws {
        let taskConfig = SetupAssigneeTask.Config()

        let task = SetupAssigneeTask(
            logger: DependenciesFactory.resolve(),
            config: taskConfig,
            gitlabCIEnvironment: DependenciesFactory.resolve(),
            gitlabApi: DependenciesFactory.resolve()
        )

        try task.run()
    }
}
