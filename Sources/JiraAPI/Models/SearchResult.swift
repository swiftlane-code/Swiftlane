//

import Foundation

public struct SearchResult: Codable {
    public let expand: String?
    public let startAt: Int
    public let maxResults: Int
    public let total: Int
    public let issues: [Issue]
}
