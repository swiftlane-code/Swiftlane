//

import Combine
import Foundation
import Networking

/// Wrapper around`GitLabAPIClient` implementing complex requests.
public class GitLabAPIComplexClient {
    let api: GitLabAPIClientProtocol

    public init(api: GitLabAPIClientProtocol) {
        self.api = api
    }

    /// Load approval rules of a merge request which require at least 1 approval.
    private func loadRequiredApprovalRules(for mr: MergeRequest)
        -> AnyPublisher<[MergeRequestApprovalRule], NetworkingError>
    {
        let allProjectApprovalRules = api.projectApprovalRules(projectId: mr.projectId)
        let allMergeRequestApprovalRules = api.mergeRequestApprovalRulesAll(projectId: mr.projectId, mergeRequestIid: mr.iid)

        return allProjectApprovalRules.combineLatest(allMergeRequestApprovalRules)
            .map { projectRules, mrRules in
                (projectRules + mrRules).filter { rule in
                    /// # CRUTCH
                    /// GitLab always says that `approvals_required=0`
                    /// for the `code_owner` rule which is wrong.
                    let approvalsRequired = (rule.ruleType == "code_owner") ? 1 : (rule.approvalsRequired ?? 0)

                    return approvalsRequired > 0 && rule.ruleType != "any_approver"
                }
            }
            .eraseToAnyPublisher()
    }
}

extension GitLabAPIComplexClient: GitLabAPIComplexClientProtocol {
    /// Load list of users who did not yet approve a Merge Request.
    ///
    /// 1) Load approval rules left (partial info) for the merge request.
    ///	2) Load full info about these rules using two requests:
    ///		* all rules of the merge request;
    ///		* all rules of the project.
    /// 3) Extract list of users from loaded full info about approval rules left.
    /// 4) Append assignees to (3).
    /// 5) Drop from (4) those users who already approved the merge request.
    ///
    func findPotentialApprovers(for mr: MergeRequest) -> AnyPublisher<Set<Member>, NetworkingError> {
        let assignedReviewers = mr.reviewers
        let approvals = api.mergeRequestApprovalRulesLeft(projectId: mr.projectId, mergeRequestIid: mr.iid)
        let allApprovalRules = loadRequiredApprovalRules(for: mr)

        return allApprovalRules.combineLatest(approvals)
            .map { allRules, approvals -> Set<Member> in
                guard !approvals.approvalRulesLeft.isEmpty else {
                    return []
                }

                let leftIds = Set(approvals.approvalRulesLeft.map(\.id))
                let leftRulesFullInfo = allRules.filter {
                    leftIds.contains($0.id)
                }
                let alreadyApprovedByIds = Set(approvals.approvedBy.compactMap(\.user).map(\.id))

                let eligibleApproversFromRules = leftRulesFullInfo
                    .compactMap(\.eligibleApprovers)
                    .flatMap { $0 }

                let allPotentialApprovers = (assignedReviewers + eligibleApproversFromRules)
                    .filter { !alreadyApprovedByIds.contains($0.id) }

                return Set(allPotentialApprovers)
            }
            .eraseToAnyPublisher()
    }

    /// Recursively load all evens of a user.
    ///
    /// Note: Pages in GitLab API are indexed starting from `1`.
    func userActivityEventsFromAllPages(
        userId: Int,
        afterDate: Date,
        startingFromPage page: Int = 1
    ) -> AnyPublisher<[UserActivityEvent], NetworkingError> {
        api.userActivityEvents(userId: userId, after: afterDate, page: page, perPage: 100)
            .flatMap { eventsOnPage -> AnyPublisher<[UserActivityEvent], NetworkingError> in
                guard !eventsOnPage.isEmpty else {
                    return Just([]).setFailureType(to: NetworkingError.self).eraseToAnyPublisher()
                }
                // Load next page if the last one loaded is not empty.
                return
                    self.userActivityEventsFromAllPages(
                        userId: userId,
                        afterDate: afterDate,
                        startingFromPage: page + 1
                    )
                    .map { eventsOnPage + $0 }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
