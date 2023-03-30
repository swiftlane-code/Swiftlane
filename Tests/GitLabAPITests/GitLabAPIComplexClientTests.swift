//

import Foundation
@testable import GitLabAPI
import SwiftlaneCore
import XCTest

class GitLabAPIComplexClientTests: XCTestCase {
    var api: GitLabAPIClientProtocolMock!
    var complex: GitLabAPIComplexClient!

    override func setUpWithError() throws {
        try super.setUpWithError()

        api = .init(sequencing: .inWritingOrder, stubbing: .drop)
        complex = GitLabAPIComplexClient(api: api)
    }

    override func tearDown() {
        super.tearDown()

        api = nil
        complex = nil
    }

    func test_loadUserActivityFromAllPages() throws {
        // given
        let userId = Int.random(in: 0 ... 1000)
        let afterDate = Date()

        let eventsPages = [
            [userActivityEventStub(), userActivityEventStub(), userActivityEventStub()],
            [userActivityEventStub()],
            [],
        ]

        eventsPages.enumerated().forEach { idx, events in
            api.given(
                .userActivityEvents(
                    userId: .value(userId),
                    after: .value(afterDate),
                    page: .value(idx + 1),
                    perPage: .value(100),
                    willReturn: .just(events)
                )
            )
        }

        // when
        let result = try complex.userActivityEventsFromAllPages(userId: userId, afterDate: afterDate).await()

        // then
        XCTAssertEqual(result.count, eventsPages.flatMap { $0 }.count)
    }

    func test_loadPotentialApprovers() throws {
        // given
        let dump = try Stubs.readDump(
            route: "projects/75700/merge_requests/3536",
            uuid: "4A0775D4-797E-4B7F-AA25-B8E1534EED76"
        ).responseBody.data(using: .utf8)!

        let mr = try GitLabAPIDeserializer().deseriaize(MergeRequest.self, from: dump)

        let anyApprovers = [
            memberStub(name: "any_1"),
            memberStub(name: "any_2"),
            memberStub(name: "any_3"),
        ]

        let codeOwners = [
            memberStub(name: "code_owner_1"),
            memberStub(name: "code_owner_2"),
            memberStub(name: "code_owner_3"),
        ]

        let project_rule_1_approvers = [
            memberStub(name: "project rule_1 unique"),
            memberStub(name: "project rule_1 and rule_2 shared"),
        ]

        let project_rule_2_approvers = [
            project_rule_1_approvers[0],
            memberStub(name: "project rule_2 unique"),
        ]

        let any_approver_rule = approvalRuleStub(ruleType: "any_approver", approvalsRequired: 4, approvers: anyApprovers)

        let projectRules: [MergeRequestApprovalRule] = [
            approvalRuleStub(ruleType: "project_rule_1", approvalsRequired: 1, approvers: project_rule_1_approvers),
            approvalRuleStub(ruleType: "project_rule_2", approvalsRequired: 1, approvers: project_rule_2_approvers),
        ]

        let mr_rule_from_file = approvalRuleStub(ruleType: "mr_rule_from_file", approvalsRequired: 1, approvers: [
            memberStub(name: "mr_rule"),
        ])

        let codeOwnersRule = approvalRuleStub(ruleType: "code_owner", approvalsRequired: 1, approvers: codeOwners)

        api.given(
            .mergeRequestApprovalRulesLeft(
                projectId: .value(mr.projectId),
                mergeRequestIid: .value(mr.iid),
                willReturn: .just(
                    MergeRequestApprovals(
                        approvalRulesLeft: [
                            codeOwnersRule,
                            any_approver_rule,
                        ] + projectRules,
                        approvedBy: [MergeRequestApprovals.ApprovedByContainer(user: memberStub())],
                        approvalsLeft: 1
                    )
                )
            )
        )

        api.given(
            .projectApprovalRules(
                projectId: .value(mr.projectId),
                willReturn: .just(projectRules)
            )
        )

        api.given(
            .mergeRequestApprovalRulesAll(
                projectId: .value(mr.projectId),
                mergeRequestIid: .value(mr.iid),
                willReturn: .just([
                    mr_rule_from_file,
                    codeOwnersRule,
                    any_approver_rule,
                ] + projectRules)
            )
        )

        // when
        let result = try complex.findPotentialApprovers(for: mr).await()

        // then
        XCTAssertEqual(result.map(\.name).sorted(), [
            "code_owner_1",
            "code_owner_2",
            "code_owner_3",
            "project rule_1 and rule_2 shared",
            "project rule_1 unique",
            "project rule_2 unique",
        ])
    }
}

private func userActivityEventStub() -> UserActivityEvent {
    UserActivityEvent(
        id: Int.random(in: 0 ... 1000),
        projectId: Int.random(in: 0 ... 1000),
        actionName: .random(),
        createdAt: Date(),
        author: memberStub(),
        targetId: Int.random(in: 0 ... 1000),
        targetIid: Int.random(in: 0 ... 1000),
        targetType: .random(),
        targetTitle: .random(),
        pushData: nil,
        note: nil
    )
}

private func memberStub(name: String = .random()) -> Member {
    Member(
        id: Int.random(in: 0 ... 1000),
        name: name,
        username: .random(),
        state: .random(),
        avatarUrl: .random(),
        webUrl: .random()
    )
}

private func approvalRuleStub(
    ruleType: String,
    approvalsRequired: Int,
    approvers: [Member]
) -> MergeRequestApprovalRule {
    MergeRequestApprovalRule(
        id: .random(in: 0 ... 100_000),
        name: .random(),
        ruleType: ruleType,
        eligibleApprovers: approvers,
        approvalsRequired: approvalsRequired
    )
}
