
// MARK: - Member

public struct Member: Decodable, Hashable {
    public let id: Int
    public let name: String
    public let username: String
    public let state: String
    public let avatarUrl: String?
    public let webUrl: String?

    public init(
        id: Int,
        name: String,
        username: String,
        state: String,
        avatarUrl: String?,
        webUrl: String?
    ) {
        self.id = id
        self.name = name
        self.username = username
        self.state = state
        self.avatarUrl = avatarUrl
        self.webUrl = webUrl
    }
}
