//

import Foundation
import Guardian
import JiraAPI
import SwiftlaneCore

public protocol ChangelogFactoring {
    func changelog() throws -> String
}

public final class ChangelogFactory {
    private let logger: Logging
    private let gitlabCIEnvironmentReader: GitLabCIEnvironmentReading
    private let jiraClient: JiraAPIClientProtocol
    private let issueKeySearcher: JiraIssueKeySearching

    public init(
        logger: Logging,
        gitlabCIEnvironmentReader: GitLabCIEnvironmentReading,
        jiraClient: JiraAPIClientProtocol,
        issueKeySearcher: JiraIssueKeySearching
    ) {
        self.logger = logger
        self.gitlabCIEnvironmentReader = gitlabCIEnvironmentReader
        self.jiraClient = jiraClient
        self.issueKeySearcher = issueKeySearcher
    }

    private func jiraIssuesInfo() throws -> String {
        let issuesKeys = try issueKeySearcher.searchIssueKeys()

        let jiraIssues = try issuesKeys
            .map {
                try jiraClient.loadIssue(issueKey: $0)
                    .await(timeout: jiraClient.requestTimeout)
            }
            .map {
                $0.key + " " + $0.fields.summary
            }

        return jiraIssues.joined(separator: ";\n") + "."
    }

    private func branchInfo() throws -> String {
        let sourceBranch = (try? gitlabCIEnvironmentReader.string(.CI_MERGE_REQUEST_SOURCE_BRANCH_NAME))
            ?? (try? gitlabCIEnvironmentReader.string(.CI_COMMIT_BRANCH))

        let targetBranch = try? gitlabCIEnvironmentReader.string(.CI_MERGE_REQUEST_TARGET_BRANCH_NAME)

        if let sourceBranch = sourceBranch, let targetBranch = targetBranch {
            return "Merge Request: " + sourceBranch + " -> " + targetBranch
        }

        return try "Branch: " + sourceBranch.unwrap(errorDescription: "Unable to read source branch of this job.")
    }
}

extension ChangelogFactory: ChangelogFactoring {
    public func changelog() throws -> String {
        let jiraInfo = try jiraIssuesInfo()
        let branchInfo = try branchInfo()

        return jiraInfo + "\n\n" + branchInfo
    }
}
