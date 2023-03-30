//

import Foundation
import SwiftlaneCore
import SwiftlaneCoreMocks
import SwiftyMocky
import XCTest

@testable import Guardian

class GitLabCIEnvironmentReaderTests: XCTestCase {
    var reader: GitLabCIEnvironmentReader!
    var environmentValueReading: EnvironmentValueReadingMock!

    override func setUp() {
        super.setUp()

        Matcher.default.register(ShellEnvKeyRepresentable.self) { lhs, rhs -> Bool in
            lhs.asShellEnvKey == rhs.asShellEnvKey
        }

        environmentValueReading = EnvironmentValueReadingMock()
        reader = GitLabCIEnvironmentReader(environmentValueReading: environmentValueReading)
    }

    override func tearDown() {
        reader = nil
        environmentValueReading = nil

        super.tearDown()
    }

    func test_readsString() throws {
        // given
        let vars: [GitLabCIEnvironmentVariable] = [
            .CI_COMMIT_TITLE,
            .CI_COMMIT_SHA,
            .CI_MERGE_REQUEST_SOURCE_BRANCH_NAME,
            .CI_COMMIT_BRANCH,
            .CI_COMMIT_DESCRIPTION,
            .CI_COMMIT_REF_NAME,
            .CI_COMMIT_SHORT_SHA,
        ]
        let variable = vars.randomElement()!
        let stub = UUID().uuidString
        environmentValueReading.given(.string(.value(variable.rawValue), willReturn: stub))

        // when
        let result = try reader.string(variable)

        // then
        XCTAssertEqual(result, stub)
    }

    func test_readsInt() throws {
        // given
        let vars: [GitLabCIEnvironmentVariable] = [
            .CI_COMMIT_TITLE,
            .CI_COMMIT_SHA,
            .CI_MERGE_REQUEST_SOURCE_BRANCH_NAME,
            .CI_COMMIT_BRANCH,
            .CI_COMMIT_DESCRIPTION,
            .CI_COMMIT_REF_NAME,
            .CI_COMMIT_SHORT_SHA,
        ]
        let variable = vars.randomElement()!
        let stub = Int.random(in: 0 ... 10000)
        environmentValueReading.given(.int(.value(variable.rawValue), willReturn: stub))

        // when
        let result = try reader.int(variable)

        // then
        XCTAssertEqual(result, stub)
    }

    func test_readsDouble() throws {
        // given
        let vars: [GitLabCIEnvironmentVariable] = [
            .CI_COMMIT_TITLE,
            .CI_COMMIT_SHA,
            .CI_MERGE_REQUEST_SOURCE_BRANCH_NAME,
            .CI_COMMIT_BRANCH,
            .CI_COMMIT_DESCRIPTION,
            .CI_COMMIT_REF_NAME,
            .CI_COMMIT_SHORT_SHA,
        ]
        let variable = vars.randomElement()!
        let stub = Double.random(in: 0 ... 10000)
        environmentValueReading.given(.double(.value(variable.rawValue), willReturn: stub))

        // when
        let result = try reader.double(variable)

        // then
        XCTAssertEqual(result, stub)
    }

    func test_readsBool() throws {
        // given
        let vars: [GitLabCIEnvironmentVariable] = [
            .CI_COMMIT_TITLE,
            .CI_COMMIT_SHA,
            .CI_MERGE_REQUEST_SOURCE_BRANCH_NAME,
            .CI_COMMIT_BRANCH,
            .CI_COMMIT_DESCRIPTION,
            .CI_COMMIT_REF_NAME,
            .CI_COMMIT_SHORT_SHA,
        ]
        let variable = vars.randomElement()!
        let stub = Bool.random()
        environmentValueReading.given(.bool(.value(variable.rawValue), willReturn: stub))

        // when
        let result = try reader.bool(variable)

        // then
        XCTAssertEqual(result, stub)
    }

    func test_mergeRequestURL() throws {
        // given
        environmentValueReading.given(
            .url(
                .value("CI_PROJECT_URL"),
                willReturn: URL(string: "https://gitlab.com/project/alpha")!
            )
        )
        environmentValueReading.given(
            .string(
                .value("CI_MERGE_REQUEST_IID"),
                willReturn: "123123"
            )
        )

        // when
        let url = try reader.mergeRequestURL()

        // then
        XCTAssertEqual(url.absoluteString, "https://gitlab.com/project/alpha/-/merge_requests/123123")
    }

    func test_assigneesUsernames() throws {
        try check_assigneesUsernames(
            assigneesVariableValue: "smb.surname, the.dev, and unnameduser",
            expectedResult: ["smb.surname", "the.dev", "unnameduser"]
        )
        try check_assigneesUsernames(
            assigneesVariableValue: "smb.surname and unnameduser",
            expectedResult: ["smb.surname", "unnameduser"]
        )
        try check_assigneesUsernames(
            assigneesVariableValue: "smb.surname",
            expectedResult: ["smb.surname"]
        )
        try check_assigneesUsernames(
            assigneesVariableValue: "smb.and.surname",
            expectedResult: ["smb.and.surname"]
        )
        try check_assigneesUsernames(
            assigneesVariableValue: "smb.and.surname, someone.and, and and.user",
            expectedResult: ["smb.and.surname", "someone.and", "and.user"]
        )
        try check_assigneesUsernames(
            assigneesVariableValue: "someone_and and and_2, someone.and, and and.user",
            expectedResult: ["someone_and", "and_2", "someone.and", "and.user"]
        )
    }

    func check_assigneesUsernames(
        assigneesVariableValue: String,
        expectedResult: [String]
    ) throws {
        // given
        environmentValueReading.given(
            .string(
                .value("CI_MERGE_REQUEST_ASSIGNEES"),
                willReturn: assigneesVariableValue
            )
        )

        // when
        let assigneesUsernames = try reader.assigneesUsernames()

        // then
        XCTAssertEqual(assigneesUsernames, expectedResult)
    }
}
