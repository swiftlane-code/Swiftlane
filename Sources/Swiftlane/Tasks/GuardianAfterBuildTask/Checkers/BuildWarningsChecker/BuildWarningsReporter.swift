//

import Foundation
import Guardian
import SwiftlaneCore

// sourcery: AutoMockable
public protocol BuildWarningsReporting {
    func reportNoWarningsDetected()
    func report(warnings: [XCLogParserIssuesReport.Issue], projectDir: AbsolutePath)
}

public class BuildWarningsReporter: BuildWarningsReporting {
    private let reporter: MergeRequestReporting
    private let issueFormatter: XCLogParserIssueFormatting
    private let failBuildWhenWarningsDetected: Bool

    public init(
        reporter: MergeRequestReporting,
        issueFormatter: XCLogParserIssueFormatting,
        failBuildWhenWarningsDetected: Bool
    ) {
        self.reporter = reporter
        self.issueFormatter = issueFormatter
        self.failBuildWhenWarningsDetected = failBuildWhenWarningsDetected
    }

    public func reportNoWarningsDetected() {
        reporter.success("New warnings not detected")
    }

    // swiftformat:disable indent
	public func report(warnings: [XCLogParserIssuesReport.Issue], projectDir: AbsolutePath) {
		let rows = warnings.map { warning in
			let prettyDescription = issueFormatter.format(issue: warning, projectDir: projectDir)

			return """
				<tr>
				<td>
				\(prettyDescription)
				</td>
				</tr>
				"""
		}.joined(separator: "\n\n")

		let message = "Build warnings detected (see table)"
		if failBuildWhenWarningsDetected {
			reporter.fail(message)
		} else {
			reporter.warn(message)
		}
		reporter.markdown("""
			### Build warnings

			<table>
			<tr>
			<th>
			Warnings
			</th>
			</tr>
			\(rows)
			</table>
			""")
	}
	// swiftformat:enable indent
}
