//

import Foundation
import SwiftlaneCore
import SwiftlaneUnitTestTools
import XCTest

@testable import Swiftlane

// swiftformat:disable indent
class ExpiringToDoParserTests: XCTestCase {
	var parser: ExpiringToDoParser!

	override func setUp() {
		super.setUp()

		parser = ExpiringToDoParser()
	}

	override func tearDown() {
		parser = nil

		super.tearDown()
	}

	func test_oneDayDistanceTodosAreCalculatedCorrectly() throws {
		// given
		let code =
		   """
		   // TODO: [26/05/3022] approaching
		   // TODO: [25/05/3022] expired today
		   // TODO: [24/05/3022] expired yesterday
		   """
		let fileName = RelativePath.random(suffix: "file.swift")

		// when
		let todos = try parser.parseToDos(from: code, fileName: fileName)

		// then
		XCTAssertEqual(todos.count, 3)
		XCTAssertEqual(todos, [
		    ParsedExpiringToDoModel(
		        file: fileName,
		        line: 1,
		        fullMatch: "// TODO: [26/05/3022] approaching",
		        author: nil,
		        dateString: "26/05/3022"
		    ),
		    ParsedExpiringToDoModel(
		        file: fileName,
		        line: 2,
		        fullMatch: "// TODO: [25/05/3022] expired today",
		        author: nil,
		        dateString: "25/05/3022"
		    ),
		    ParsedExpiringToDoModel(
		        file: fileName,
		        line: 3,
		        fullMatch: "// TODO: [24/05/3022] expired yesterday",
		        author: nil,
		        dateString: "24/05/3022"
		    ),
		])
	}
}
