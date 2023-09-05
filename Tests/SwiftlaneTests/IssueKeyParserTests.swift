//

@testable import Swiftlane
import XCTest

final class IssueKeyParserTests: XCTestCase {
    func test_parsingCommentInGitLab() throws {
        let parser = JiraIssueKeyParser(jiraProjectKey: "ABCD")

        try XCTAssertEqual(
            parser.parse(from: "ABCD-0000 test"),
            ["ABCD-0000"]
        )
        try XCTAssertEqual(
            parser.parse(from: "ABCD-1234 test"),
            ["ABCD-1234"]
        )
        try XCTAssertEqual(
            parser.parse(from: "ABCD-12 test"),
            ["ABCD-12"]
        )
        try XCTAssertEqual(
            parser.parse(from: "ABCD- test"),
            []
        )
        try XCTAssertEqual(
            parser.parse(from: "ABCD-0000"),
            ["ABCD-0000"]
        )
        try XCTAssertEqual(
            parser.parse(from: "APNI-0000 Tests"),
            []
        )
        try XCTAssertEqual(
            parser.parse(from: "ABCD-34,ABCD-22, (ABCD-5),,,,AABCD-4, ABCD-1 ABCD-1 ABCD-3"),
            ["ABCD-1", "ABCD-22", "ABCD-3", "ABCD-34", "ABCD-5"]
        )
    }
}
