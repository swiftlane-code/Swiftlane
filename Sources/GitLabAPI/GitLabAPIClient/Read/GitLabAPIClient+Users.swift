//

import Combine
import Foundation
import Networking

/// Working with users.
public extension GitLabAPIClient {
    func userActivityEvents(
        userId: Int,
        after: Date,
        page: Int,
        perPage: Int
    ) -> AnyPublisher<[UserActivityEvent], NetworkingError> {
        client
            .get("users/\(userId)/events")
            .with(queryItems: [
                "page": page,
                "per_page": perPage,
                "after": after.shortISO8601String,
            ])
            .perform()
    }

    func groupMembers(
        group: GitLab.Group
    ) -> AnyPublisher<[Member], NetworkingError> {
        client
            .get("groups/\(group.id)/members")
            .with(queryItems: ["per_page": 100])
            .perform()
    }

    func groupDetails(
        group: GitLab.Group
    ) -> AnyPublisher<Group, NetworkingError> {
        // https://docs.gitlab.com/ee/api/groups.html#details-of-a-group
        client
            .get("groups/\(group.id)")
            .perform()
    }
}
