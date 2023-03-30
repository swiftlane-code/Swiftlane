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
        logger: Logging
    ) throws {
        let environmentValueReader = EnvironmentValueReader()
        let gitlabCIEnvironmentReader = GitLabCIEnvironmentReader(environmentValueReading: environmentValueReader)

        let issueKeySearcher = IssueKeySearcher(
            logger: logger,
            issueKeyParser: IssueKeyParser(jiraProjectKey: sharedConfig.values.jiraProjectKey),
            gitlabCIEnvironmentReader: gitlabCIEnvironmentReader
        )

        let taskConfig = AddJiraIssueCommentTask.Config(
            text: params.text,
            ignoredIssues: commandConfig.ignoredIssues
        )

        let jiraClient = try JiraAPIClient(
            requestsTimeout: sharedConfig.values.jiraRequestsTimeout,
            logger: logger
        )

        let task = AddJiraIssueCommentTask(
            logger: logger,
            jiraClient: jiraClient,
            issueKeySearcher: issueKeySearcher,
            config: taskConfig
        )

        let projectPath = try gitlabCIEnvironmentReader.string(.CI_PROJECT_PATH)
        guard sharedConfig.values.availableProjects.isMatching(string: projectPath) else {
            logger.warn("Skipped run task about project with path \(projectPath.quoted)")
            return
        }

        try task.run(sharedConfig: sharedConfig.values)
    }
}
