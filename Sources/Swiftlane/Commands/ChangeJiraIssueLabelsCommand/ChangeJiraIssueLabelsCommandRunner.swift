
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
        let _ = try JiraAPIClient(requestsTimeout: sharedConfig.values.jiraRequestsTimeout, logger: logger)
        return true
    }

    public func run(
        params: ChangeJiraIssueLabelsCommandParamsAccessing,
        commandConfig _: ChangeJiraIssueLabelsCommandConfig,
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

        let taskConfig = ChangeJiraIssueLabelsTask.Config(
            neededLabels: params.neededLabels,
            appendLabels: params.appendLabels
        )

        let jiraClient = try JiraAPIClient(
            requestsTimeout: sharedConfig.values.jiraRequestsTimeout,
            logger: logger
        )

        let task = ChangeJiraIssueLabelsTask(
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
