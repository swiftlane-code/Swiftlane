//

import Foundation
import SwiftlaneCore

public protocol IssueKeyParsing {
    /// Parse all jira issue keys from string.
    func parse(from description: String) throws -> [String]
}

// Parser of jira issue key.
public struct IssueKeyParser {
    public let jiraProjectKey: String

    public init(jiraProjectKey: String) {
        self.jiraProjectKey = jiraProjectKey
    }
}

extension IssueKeyParser: IssueKeyParsing, Parsing {
    /// Parse all jira issue keys from string.
    public func parse(from description: String) throws -> [String] {
        let regex = try NSRegularExpression(
            // "(?<!\w)" means that regex won't match after a 'word' character.
            pattern: #"(?<!\w)\#(jiraProjectKey)-\d+"#,
            options: .anchorsMatchLines
        )
        return regex.matches(in: description).unique.sorted()
    }
}
