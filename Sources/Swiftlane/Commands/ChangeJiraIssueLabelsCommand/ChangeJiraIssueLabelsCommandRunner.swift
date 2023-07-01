
import Foundation
import Guardian
import JiraAPI
import Simulator
import SwiftlaneCore
import Yams

public struct ChangeJiraIssueLabelsCommandConfig: Decodable {}

public struct ChangeJiraIssueLabelsCommandRunner: CommandRunnerProtocol {
    public func verifyConfigs(
        params _: ChangeJiraIssueLabelsCommandParamsAccessing,
        commandConfig _: ChangeJiraIssueLabelsCommandConfig,
        sharedConfig: SharedConfigData,
        logger: Logging
    ) throws -> Bool {
        return true
    }

    public func run(
        params: ChangeJiraIssueLabelsCommandParamsAccessing,
        commandConfig _: ChangeJiraIssueLabelsCommandConfig,
        sharedConfig: SharedConfigData,
        logger _: Logging
    ) throws {
        let taskConfig = ChangeJiraIssueLabelsTask.Config(
            neededLabels: params.neededLabels,
            appendLabels: params.appendLabels
        )

        let task = try TasksFactory.makeChangeJiraIssueLabelsTask(taskConfig: taskConfig)

        try task.run(sharedConfig: sharedConfig.values)
    }
}
