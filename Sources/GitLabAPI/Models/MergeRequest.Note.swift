//

import Foundation

public extension MergeRequest {
    struct Note: Decodable {
        public let id: Int
        public let body: String
        //		public let attachment: Any
        public let author: Member
        public let createdAt: Date
        public let updatedAt: Date
        public let system: Bool
        public let noteableId: Int
        public let noteableType: String
        public let noteableIid: Int
        public let resolvable: Bool
        public let confidential: Bool

        public init(
            id: Int,
            body: String,
            author: Member,
            createdAt: Date,
            updatedAt: Date,
            system: Bool,
            noteableId: Int,
            noteableType: String,
            noteableIid: Int,
            resolvable: Bool,
            confidential: Bool
        ) {
            self.id = id
            self.body = body
            self.author = author
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.system = system
            self.noteableId = noteableId
            self.noteableType = noteableType
            self.noteableIid = noteableIid
            self.resolvable = resolvable
            self.confidential = confidential
        }
    }
}
