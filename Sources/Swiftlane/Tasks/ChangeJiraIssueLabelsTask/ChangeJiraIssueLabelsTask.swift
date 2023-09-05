
import Foundation
import JiraAPI
import Networking
import SwiftlaneCore

public extension ChangeJiraIssueLabelsTask {
    struct Config {
        public let neededLabels: [String]
        public let appendLabels: Bool
    }
}

public final class ChangeJiraIssueLabelsTask {
    private let logger: Logging
    private let jiraClient: JiraAPIClientProtocol
    private let issueKeySearcher: JiraIssueKeySearcher
    private let config: Config

    public init(
        logger: Logging,
        jiraClient: JiraAPIClientProtocol,
        issueKeySearcher: JiraIssueKeySearcher,
        config: Config
    ) {
        self.logger = logger
        self.jiraClient = jiraClient
        self.issueKeySearcher = issueKeySearcher
        self.config = config
    }

    /// Prepare target labels based on Issue's current labels and `config.neededLabels`.
    /// - Returns: target labels for the issue.
    public func prepareLabels(for jiraIssue: Issue) -> [String] {
        guard config.appendLabels else {
            return config.neededLabels
        }
        return Set(config.neededLabels)
            .union(jiraIssue.fields.labels)
            .sorted()
    }

    public func run(
        sharedConfig: SharedConfigValues
    ) throws {
        logger.info("Run change JIRA task labels for labels: \(config.neededLabels). Needed append labels \(config.appendLabels)")

        let issuesKeys = try issueKeySearcher.searchIssueKeys()

        logger.info("Issues to change labels of: \(issuesKeys)")

        try issuesKeys.forEach {
            try setLabels(issueKey: $0, sharedConfig: sharedConfig)
        }
    }

    private func setLabels(
        issueKey: String,
        sharedConfig: SharedConfigValues
    ) throws {
        let jiraIssue = try jiraClient.loadIssue(issueKey: issueKey)
            .await(timeout: sharedConfig.jiraRequestsTimeout)

        let resultLabels = prepareLabels(for: jiraIssue)

        guard jiraIssue.fields.labels != resultLabels else {
            logger.warn("There are no new updates to the label array of \(issueKey).")
            return
        }

        try jiraClient.updateLabels(issueKey: issueKey, labels: resultLabels)
            .await(timeout: sharedConfig.jiraRequestsTimeout)
    }
}
