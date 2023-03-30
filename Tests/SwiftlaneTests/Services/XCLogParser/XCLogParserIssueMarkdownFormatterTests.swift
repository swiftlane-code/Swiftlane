//

import Foundation
import SwiftlaneCore
import XCTest

@testable import Swiftlane

// swiftformat:disable indent
class XCLogParserIssueMarkdownFormatterTests: XCTestCase {
	let formatter = XCLogParserIssueMarkdownFormatter()

	func test_formatWithoutDetail() throws {
		// given
		let projectDir = try AbsolutePath("/abs/path")
		let issue = XCLogParserIssuesReport.Issue(
		    type: .error,
		    title: "Missing argument for parameter 'inputModel' in call",
		    clangFlag: nil,
		    documentURL: "file:///abs/path/TTTests/Main/ModulesTests.swift",
		    severity: 2,
		    startingLineNumber: 67,
		    endingLineNumber: 68,
		    startingColumnNumber: 29,
		    endingColumnNumber: 30,
		    characterRangeEnd: 18_446_744_073_709_551_615,
		    characterRangeStart: 0,
		    interfaceBuilderIdentifier: nil,
		    detail: nil
		)

		// when
		let formatted = formatter.format(issue: issue, projectDir: projectDir)

		// then
		XCTAssertEqual(
		    formatted,
		    "<p><strong>Error: Missing argument for parameter 'inputModel' in call<strong></p>\n" +
			"<p>TTTests/Main/ModulesTests.swift:67:29</p>"
		)
	}

	func test_formatWithDetail() throws {
		// given
		let projectDir = try AbsolutePath("/abs/path")
		let issue = XCLogParserIssuesReport.Issue(
		    type: .swiftError,
		    title: "Incorrect argument label in call (have 'city:', expected 'source:')",
		    clangFlag: nil,
		    documentURL: "file:///abs/path/TTTests/Main/ModulesTests.swift",
		    severity: 2,
		    startingLineNumber: 271,
		    endingLineNumber: 272,
		    startingColumnNumber: 25,
		    endingColumnNumber: 26,
		    characterRangeEnd: 18_446_744_073_709_551_615,
		    characterRangeStart: 0,
		    interfaceBuilderIdentifier: nil,
		    detail: "/abs/path/TTTests/Main/ModulesTests.swift:271:25: error: incorrect argument label in call (have 'city:', expected 'source:')\n\tpresenter.update(city: city)\n\t\t\t^~~~~\n\t\t\t source"
		)

		// when
		let formatted = formatter.format(issue: issue, projectDir: projectDir)

		// then
		XCTAssertEqual(
		    formatted,
		    """
			<p><strong>SwiftError: Incorrect argument label in call (have 'city:', expected 'source:')<strong></p>
			<p>TTTests/Main/ModulesTests.swift:271:25</p>
			<pre>
			error: incorrect argument label in call (have 'city:', expected 'source:')
			\tpresenter.update(city: city)
			\t\t\t^~~~~
			\t\t\t source
			</pre>
			"""
		)
	}
}
