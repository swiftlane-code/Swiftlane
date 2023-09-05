
import Foundation
import JiraAPI
import Networking
import SwiftlaneCore

public extension AddJiraIssueCommentTask {
    struct Config {
        public let text: String
        public let ignoredIssues: [StringMatcher]
    }
}

public final class AddJiraIssueCommentTask {
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

    public func run(
        sharedConfig: SharedConfigValues
    ) throws {
        logger.info("Running add comment to JIRA issue: \(config.text.quoted)")

        let issuesKeys = try issueKeySearcher.searchIssueKeys()

        logger.info("Issues to add comment to: \(issuesKeys)")

        try issuesKeys.forEach {
            try addComment(
                issueKey: $0,
                text: config.text,
                sharedConfig: sharedConfig
            )
        }
    }

    private func addComment(
        issueKey: String,
        text: String,
        sharedConfig: SharedConfigValues
    ) throws {
        guard !config.ignoredIssues.isMatching(string: issueKey) else {
            logger.warn("Ignoring issue \(issueKey.quoted) because of command config.")
            return
        }

        try jiraClient.addComment(issueKey: issueKey, text: text)
            .await(timeout: sharedConfig.jiraRequestsTimeout)
    }
}
