//

import Combine
import Foundation
import Networking

/// Functions to work with MR approvals.
public extension GitLabAPIClient {
    /// All approval rules (full info) of a project.
    func projectApprovalRules(
        projectId: Int
    ) -> AnyPublisher<[MergeRequestApprovalRule], NetworkingError> {
        client
            .get("projects/\(projectId)/approval_rules")
            .perform()
    }

    /// All approval rules (full info) of a Merge Request.
    func mergeRequestApprovalRulesAll(
        projectId: Int,
        mergeRequestIid: Int
    ) -> AnyPublisher<[MergeRequestApprovalRule], NetworkingError> {
        client
            .get("projects/\(projectId)/merge_requests/\(mergeRequestIid)/approval_rules")
            .perform()
    }

    /// Information about current state of approval rules of a Merge Request.
    /// `approvalRulesLeft` containts only partial info (id and name).
    func mergeRequestApprovalRulesLeft(
        projectId: Int,
        mergeRequestIid: Int
    ) -> AnyPublisher<MergeRequestApprovals, NetworkingError> {
        client
            .get("projects/\(projectId)/merge_requests/\(mergeRequestIid)/approvals")
            .perform()
    }
}
