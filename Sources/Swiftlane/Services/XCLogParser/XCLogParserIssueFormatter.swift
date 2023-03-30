//

import Foundation
import SwiftlaneCore

public protocol XCLogParserIssueFormatting {
    /// Make pretty Markdown formatted description for an issue.
    /// - Parameters:
    ///   - issue: Build error or warning.
    ///   - projectDir: Absolute path to project.
    func format(issue: XCLogParserIssuesReport.Issue, projectDir: AbsolutePath) -> String
}

public final class XCLogParserIssueMarkdownFormatter: XCLogParserIssueFormatting {
    public init() {}

    /// Make pretty Markdown formatted description for an issue.
    /// - Parameters:
    ///   - issue: Build error or warning.
    ///   - projectDir: Absolute path to project.
    public func format(issue: XCLogParserIssuesReport.Issue, projectDir: AbsolutePath) -> String {
        var result = [String]()
        var stringsToRemoveFromDetail = [String]()

        let title = issue.title
        let pathPartToDelete = projectDir.string + "/"

        stringsToRemoveFromDetail.append(pathPartToDelete) // Delete absolute path part
        stringsToRemoveFromDetail.append(issue.title) // Delete `title`

        result.append("<p><strong>\(issue.type.rawValue.uppercasedFirst): \(title)<strong></p>")

        if let documentPath = issue.documentPath {
            let fileRelativePath = documentPath.string.replacingOccurrences(of: pathPartToDelete, with: "")
            let fileLineColumn = "\(fileRelativePath):\(issue.startingLineNumber):\(issue.startingColumnNumber)"
            result.append("<p>\(fileLineColumn)</p>")
            stringsToRemoveFromDetail.append(fileLineColumn + ": ") // Delete path to file
        }

        guard let detail = issue.detail else {
            return result.joined(separator: "\n")
        }

        // swiftformat:disable trailingClosures
        let detailCleaned = stringsToRemoveFromDetail
            .reduce(detail, { $0.replacingOccurrences(of: $1, with: "") })
            .trimmingCharacters(in: .whitespacesAndNewlines)

        result.append("<pre>\n\(detailCleaned)\n</pre>")
        return result.joined(separator: "\n")
    }
}
