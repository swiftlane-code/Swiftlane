//

import Foundation
import Guardian
import SwiftlaneCore

public extension IssueKeySearcher {
    enum Errors: Error {
        case requiredEnvironmentsAreMissing(description: String)
        case notFoundIssueKey
    }
}

// sourcery: AutoMockable
public protocol IssueKeySearching {
    func searchIssueKeys() throws -> [String]
}

public struct IssueKeySearcher: IssueKeySearching {
    public let logger: Logging
    public let issueKeyParser: IssueKeyParser
    public let gitlabCIEnvironmentReader: GitLabCIEnvironmentReading

    public init(logger: Logging, issueKeyParser: IssueKeyParser, gitlabCIEnvironmentReader: GitLabCIEnvironmentReading) {
        self.logger = logger
        self.issueKeyParser = issueKeyParser
        self.gitlabCIEnvironmentReader = gitlabCIEnvironmentReader
    }

    /// Returns array of Jira issue keys.
    /// **Never returns empty array, instead throws a error in such case.**
    public func searchIssueKeys() throws -> [String] {
        let possibleStringsWithIssueKeys = [
            try? gitlabCIEnvironmentReader.string(.CI_MERGE_REQUEST_TITLE),
            try? gitlabCIEnvironmentReader.string(.CI_COMMIT_MESSAGE),
        ]
        .compactMap { $0 }
        .unique
        .sorted()

        guard !possibleStringsWithIssueKeys.isEmpty else {
            throw Errors.requiredEnvironmentsAreMissing(
                description: "Neither CI_COMMIT_MESSAGE nor CI_MERGE_REQUEST_TITLE is present."
            )
        }

        logger.debug("Looking for Jira issue keys in \(possibleStringsWithIssueKeys)")

        let result = try possibleStringsWithIssueKeys
            .compactMap { $0 }
            .flatMap { try issueKeyParser.parse(from: $0) }
            .unique
            .sorted()

        guard !result.isEmpty else {
            throw Errors.notFoundIssueKey
        }

        logger.info("Jira issue keys found: \(result)")
        return result
    }
}
