//

import Foundation
import Guardian
import JiraAPI
import Simulator
import SwiftlaneCore
import Yams

public struct AddJiraIssueCommentCommandConfig: Decodable {
    public let ignoredIssues: [StringMatcher]
}

public struct AddJiraIssueCommentCommandRunner: CommandRunnerProtocol {
    public func run(
        params: AddJiraIssueCommentCommandParamsAccessing,
        commandConfig: AddJiraIssueCommentCommandConfig,
        sharedConfig: SharedConfigData,
        logger _: Logging
    ) throws {
        let taskConfig = AddJiraIssueCommentTask.Config(
            text: params.text,
            ignoredIssues: commandConfig.ignoredIssues
        )

        let task = TasksFactory.makeAddJiraIssueCommentTask(taskConfig: taskConfig)

        try task.run(sharedConfig: sharedConfig.values)
    }
}
