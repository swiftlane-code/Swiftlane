//

import Foundation

public enum MergeRequestInfo {
    /// Abstraction describing a merge request's author.
    ///
    /// ATM it is suited to describe a GitLab user.
    public struct Author: Decodable, Hashable {
        public let id: Int
        public let name: String
        public let username: String
        public let avatarUrl: String?
        public let webUrl: String?

        public init(
            id: Int,
            name: String,
            username: String,
            avatarUrl: String?,
            webUrl: String?
        ) {
            self.id = id
            self.name = name
            self.username = username
            self.avatarUrl = avatarUrl
            self.webUrl = webUrl
        }
    }
}
