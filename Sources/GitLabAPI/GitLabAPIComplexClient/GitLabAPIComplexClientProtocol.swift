//

import Combine
import Foundation
import Networking

protocol GitLabAPIComplexClientProtocol {
    // MARK: - GitLabAPIClient+PotentialApprovers

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
    func findPotentialApprovers(for mr: MergeRequest) -> AnyPublisher<Set<Member>, NetworkingError>

    /// Recursively load all evens of a user.
    ///
    /// Note: Pages in GitLab API are indexed starting from `1`.
    func userActivityEventsFromAllPages(
        userId: Int,
        afterDate: Date,
        startingFromPage page: Int
    ) -> AnyPublisher<[UserActivityEvent], NetworkingError>
}
