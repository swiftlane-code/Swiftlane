//

import Combine
import Foundation
import XCTest

@testable import JiraAPI
import SwiftlaneCore
import SwiftlaneCoreMocks
import SwiftlaneUnitTestTools

@testable import Swiftlane

class ChangelogFactoryTests: XCTestCase {
    var factory: ChangelogFactory!

    var logger: LoggingMock!
    var gitlabCIEnvironmentReader: GitLabCIEnvironmentReadingMock!
    var jiraClient: JiraAPIClientProtocolMock!
    var issueKeySearcher: JiraIssueKeySearchingMock!

    override func setUp() {
        super.setUp()

        logger = LoggingMock()
        gitlabCIEnvironmentReader = GitLabCIEnvironmentReadingMock()
        jiraClient = JiraAPIClientProtocolMock()
        issueKeySearcher = JiraIssueKeySearchingMock()

        factory = ChangelogFactory(
            logger: logger,
            gitlabCIEnvironmentReader: gitlabCIEnvironmentReader,
            jiraClient: jiraClient,
            issueKeySearcher: issueKeySearcher
        )
    }

    override func tearDown() {
        factory = nil

        logger = nil
        gitlabCIEnvironmentReader = nil
        jiraClient = nil
        issueKeySearcher = nil

        super.tearDown()
    }

    func test_changelogForMergeRequest() throws {
        // given
        let jiraIssue_ABCD_1080 = try jiraIssueStub(key: "ABCD-1080", summary: "Some task")
        let jiraIssue_ABCD_2940 = try jiraIssueStub(key: "ABCD-2940", summary: "Some important task")

        issueKeySearcher.given(.searchIssueKeys(willReturn: ["ABC-123", "ABC-45678"]))

        gitlabCIEnvironmentReader.given(.string(.value(.CI_MERGE_REQUEST_SOURCE_BRANCH_NAME), willReturn: "feature/ABC-123"))
        gitlabCIEnvironmentReader.given(.string(.value(.CI_MERGE_REQUEST_TARGET_BRANCH_NAME), willReturn: "develop"))

        jiraClient.given(.requestTimeout(getter: 10))
        jiraClient.given(.loadIssue(issueKey: .value("ABC-123"), willReturn: .just(jiraIssue_ABCD_1080)))
        jiraClient.given(.loadIssue(issueKey: .value("ABC-45678"), willReturn: .just(jiraIssue_ABCD_2940)))

        // when
        let changelog = try factory.changelog()

        // then
        XCTAssertEqual(
            changelog,
            [
                "ABCD-1080 Some task;",
                "ABCD-2940 Some important task.",
                "",
                "Merge Request: feature/ABC-123 -> develop",
            ].joined(separator: "\n")
        )
    }

    func test_changelogForBranchCommit() throws {
        // given
        let jiraIssue_ABCD_1080 = try jiraIssueStub(key: "ABCD-1080", summary: "Some task")

        issueKeySearcher.given(.searchIssueKeys(willReturn: ["ABC-123"]))

        gitlabCIEnvironmentReader.given(.string(.value(.CI_COMMIT_BRANCH), willReturn: "release/6.102.100"))

        gitlabCIEnvironmentReader.given(
            .string(
                .value(.CI_MERGE_REQUEST_SOURCE_BRANCH_NAME),
                willThrow: EnvironmentValueReader.Errors.variableIsNotSet(name: "")
            )
        )
        gitlabCIEnvironmentReader.given(
            .string(
                .value(.CI_MERGE_REQUEST_TARGET_BRANCH_NAME),
                willThrow: EnvironmentValueReader.Errors.variableIsNotSet(name: "")
            )
        )

        jiraClient.given(.requestTimeout(getter: 10))
        jiraClient.given(.loadIssue(issueKey: .value("ABC-123"), willReturn: .just(jiraIssue_ABCD_1080)))

        // when
        let changelog = try factory.changelog()

        // then
        XCTAssertEqual(
            changelog,
            [
                "ABCD-1080 Some task.",
                "",
                "Branch: release/6.102.100",
            ].joined(separator: "\n")
        )
    }

    private func jiraIssueStub(key: String, summary: String) throws -> JiraAPI.Issue {
        Issue(
            id: "\(Int.random(in: 100 ... 999))",
            key: key,
            fields: Fields(
                assignee: nil,
                creator: User(key: "", displayName: "", emailAddress: "", linkString: ""),
                fixVersions: [],
                labels: [],
                reporter: User(key: "", displayName: "", emailAddress: "", linkString: ""),
                priority: Priority(name: "", id: "", linkString: ""),
                status: Status(description: "", id: "", name: "", linkString: ""),
                type: Issue.IssueType(name: ""),
                subtasks: [],
                project: Fields.Project(id: ""),
                summary: summary,
                parent: nil,
                allData: [:]
            )
        )
    }
}
