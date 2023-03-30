//

import Foundation
import Guardian
import SwiftlaneCore

// sourcery: AutoMockable
public protocol BuildErrorsReporting {
    func report(errors: [XCLogParserIssuesReport.Issue], projectDir: AbsolutePath)
}

public class BuildErrorsReporter: BuildErrorsReporting {
    private let reporter: MergeRequestReporting
    private let issueFormatter: XCLogParserIssueFormatting

    public init(
        reporter: MergeRequestReporting,
        issueFormatter: XCLogParserIssueFormatting
    ) {
        self.reporter = reporter
        self.issueFormatter = issueFormatter
    }

    // swiftformat:disable indent
	public func report(errors: [XCLogParserIssuesReport.Issue], projectDir: AbsolutePath) {
		let rows = errors.map { error in
			let prettyDescription = issueFormatter.format(issue: error, projectDir: projectDir)

			return """
				<tr>
				<td>
				\(prettyDescription)
				</td>
				</tr>
				"""
		}.joined(separator: "\n\n")

		reporter.fail("Build failed 🥲")
		reporter.markdown("""
			### Build errors

			<table>
			<tr>
			<th>
			Errors
			</th>
			</tr>
			\(rows)
			</table>
			""")
	}
	// swiftformat:enable indent
}
