//

import Foundation

public struct FileContent: Codable {
    public let commitId: String
    public let content: Data
}

public struct UpdateFileContent: Encodable {
    public let branch: String
    public let commitMessage: String
    public let content: String

    public init(branch: String, commitMessage: String, content: String) {
        self.branch = branch
        self.commitMessage = commitMessage
        self.content = content
    }
}
