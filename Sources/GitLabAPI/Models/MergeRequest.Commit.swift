//

import Foundation

public extension MergeRequest {
    struct Commit: Codable {
        public let longSHA: String
        public let shortSHA: String
        public let createdAt: String
        public let parentIds: [String]
        public let title: String
        public let message: String
        public let authorName: String
        public let authorEmail: String
        public let authoredDate: String
        public let committerName: String
        public let committerEmail: String
        public let committedDate: String
        public let webUrl: String

        enum CodingKeys: String, CodingKey {
            case longSHA = "id"
            case shortSHA = "shortId"
            case createdAt
            case parentIds
            case title
            case message
            case authorName
            case authorEmail
            case authoredDate
            case committerName
            case committerEmail
            case committedDate
            case webUrl
        }
    }
}
