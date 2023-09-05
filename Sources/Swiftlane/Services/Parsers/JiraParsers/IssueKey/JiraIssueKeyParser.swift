//

import Foundation
import SwiftlaneCore

public protocol JiraIssueKeyParsing {
    /// Parse all jira issue keys from string.
    func parse(from string: String) throws -> [String]
}

// Parser of jira issue key.
public struct JiraIssueKeyParser {
    public let jiraProjectKey: String

    public init(jiraProjectKey: String) {
        self.jiraProjectKey = jiraProjectKey
    }
}

extension JiraIssueKeyParser: JiraIssueKeyParsing, Parsing {
    /// Parse all jira issue keys from string.
    public func parse(from string: String) throws -> [String] {
        let regex = try NSRegularExpression(
            // "(?<!\w)" means that regex won't match after a 'word' character.
            pattern: #"(?<!\w)\#(jiraProjectKey)-\d+"#,
            options: .anchorsMatchLines
        )
        return regex.matches(in: string).unique.sorted()
    }
}
