
import Foundation
import Guardian
import JiraAPI
import Simulator
import SwiftlaneCore
import Yams

public struct ChangeJiraIssueLabelsCommandConfig: Decodable {}

public struct ChangeJiraIssueLabelsCommandRunner: CommandRunnerProtocol {
    public func run(
        params: ChangeJiraIssueLabelsCommandParamsAccessing,
        commandConfig _: ChangeJiraIssueLabelsCommandConfig,
        sharedConfig: SharedConfigData
    ) throws {
        let taskConfig = ChangeJiraIssueLabelsTask.Config(
            neededLabels: params.neededLabels,
            appendLabels: params.appendLabels
        )

        let task = try TasksFactory.makeChangeJiraIssueLabelsTask(taskConfig: taskConfig)

        try task.run(sharedConfig: sharedConfig.values)
    }
}
