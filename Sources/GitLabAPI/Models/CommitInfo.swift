//

import Foundation

public struct CommitInfo: Decodable {
    public let id: String
    public let shortId: String
    public let title: String
    public let authorName: String
    public let authorEmail: String
    public let createdAt: String
    public let webUrl: String?
}
