//

import Foundation

public struct Pipeline: Decodable {
    public let id: Int
    public let iid: Int
    public let projectId: Int
    public let sha: String
    public let ref: String
    public let status: String
    public let source: String
    public let createdAt: Date
    public let updatedAt: Date
    public let webUrl: String?
    public let beforeSha: String
    public let tag: Bool
    public let user: Member
    public let startedAt: Date?
    public let finishedAt: Date?
}

public struct CreatePipeline: Encodable {
    public struct Variable: Encodable {
        public let key: String
        public let value: String

        public init(key: String, value: String) {
            self.key = key
            self.value = value
        }
    }

    public let ref: String
    public let variables: [Variable]?

    public init(ref: String, variables: [Variable]?) {
        self.ref = ref
        self.variables = variables
    }
}
