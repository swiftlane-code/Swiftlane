//

import Foundation

/// Note: Model is not full. Parsed from response of https://docs.gitlab.com/ee/api/groups.html#details-of-a-group
public struct Group: Decodable, Hashable {
    public let id: Int
    public let name: String
    public let path: String
    public let description: String
    public let avatarUrl: String?
    public let webUrl: String?

    public init(id: Int, name: String, path: String, description: String, avatarUrl: String?, webUrl: String?) {
        self.id = id
        self.name = name
        self.path = path
        self.description = description
        self.avatarUrl = avatarUrl
        self.webUrl = webUrl
    }
}
