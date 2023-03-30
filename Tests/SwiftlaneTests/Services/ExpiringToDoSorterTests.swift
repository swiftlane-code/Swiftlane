//

import Foundation
import SwiftlaneCore
import SwiftlaneUnitTestTools
import XCTest

@testable import Swiftlane

class ExpiringToDoSorterTests: XCTestCase {
    var sorter: ExpiringToDoSorter!

    override func setUp() {
        super.setUp()

        sorter = ExpiringToDoSorter()
    }

    override func tearDown() {
        sorter = nil

        super.tearDown()
    }

    func test_sortingIsCorrect() throws {
        // given
        let todos = [
            VerifiedExpiringTodoModel(
                parsed: .random(),
                status: .approachingExpiryDate(daysLeft: 100)
            ),
            VerifiedExpiringTodoModel(
                parsed: .random(),
                status: .expiredError(daysAgo: 1)
            ),
            VerifiedExpiringTodoModel(
                parsed: .random(),
                status: .expiredError(daysAgo: 2)
            ),
            VerifiedExpiringTodoModel(
                parsed: .random(),
                status: .approachingExpiryDate(daysLeft: 50)
            ),
            VerifiedExpiringTodoModel(
                parsed: .random(),
                status: .approachingExpiryDate(daysLeft: 5)
            ),
            VerifiedExpiringTodoModel(
                parsed: .random(),
                status: .approachingExpiryDate(daysLeft: 0)
            ),
        ]

        // when
        let sorted = sorter.sort(todos: todos)

        // then
        XCTAssertEqual(todos.count, 6)
        XCTAssertEqual(sorted.count, todos.count)
        XCTAssertEqual(try sorted.firstIndex(of: todos[safe: 0].unwrap()), 5)
        XCTAssertEqual(try sorted.firstIndex(of: todos[safe: 1].unwrap()), 0)
        XCTAssertEqual(try sorted.firstIndex(of: todos[safe: 2].unwrap()), 1)
        XCTAssertEqual(try sorted.firstIndex(of: todos[safe: 3].unwrap()), 4)
        XCTAssertEqual(try sorted.firstIndex(of: todos[safe: 4].unwrap()), 3)
        XCTAssertEqual(try sorted.firstIndex(of: todos[safe: 5].unwrap()), 2)
    }
}
