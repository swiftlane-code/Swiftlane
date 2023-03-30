//

import Foundation

public struct Issue: Codable {
    public let id: String
    public let key: String
    public let fields: Fields

    public struct IssueType: Codable {
        public let name: String
    }

    public struct SubtasksFields: Codable {
        public let issuetype: IssueType
    }

    public struct Subtasks: Codable {
        public let fields: SubtasksFields
    }

    public struct ParentTask: Codable {
        public let id: String
        public let key: String
    }
}
