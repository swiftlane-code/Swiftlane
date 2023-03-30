//

import Foundation
import SwiftlaneCore

// swiftformat:disable indent
public class MergeRequestReportFactory: MergeRequestReportFactoring {
	private let captionProvider: MergeRequestReportCaptionProviding

	public init(captionProvider: MergeRequestReportCaptionProviding) {
		self.captionProvider = captionProvider
	}

	public func reportBody(
	    fails: [String],
	    warns: [String],
	    messages: [String],
	    markdowns: [String],
	    successes: [String],
	    invisibleMark: String,
	    commitSHA: String
	) -> String {
		let failsTable = MarkdownTableBuilder(
			rows: fails.map {
				["⛔️", $0]
			}
		)

		let warnsTable = MarkdownTableBuilder(
			rows: warns.map {
				["⚠️", $0]
			}
		)

		let successesTable = MarkdownTableBuilder(
			rows: successes.map {
				["✅", $0]
			}
		)

		let messagesTable = MarkdownTableBuilder(
			rows: messages.map {
				["📝", $0]
			}
		)

		let report =
			"""
			\(invisibleMark)

			\(failsTable.build(title: "## Failures"))

			\(warnsTable.build(title: "## Warnings"))

			\(messagesTable.build(title: "## Messages"))

			\(successesTable.build(title: "## Success"))

			## Markdowns
			\(markdowns.joined(separator: "\n\n"))

			\(captionProvider.reportCaption(commitSHA: commitSHA))
			"""

		return report
	}
}

// swiftformat:enable indent
