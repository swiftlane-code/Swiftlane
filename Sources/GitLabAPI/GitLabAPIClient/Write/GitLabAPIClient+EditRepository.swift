//

import Combine
import Foundation
import Networking

/// Modifying repo files.
public extension GitLabAPIClient {
    /// Update file contents.
    func updateRepositoryFile(
        path: String,
        projectId: Int,
        bodyModel: UpdateFileContent
    ) -> AnyPublisher<Void, NetworkingError> {
        let escapedPath = path.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? path
        return client
            .put("projects/\(projectId)/repository/files/\(escapedPath)")
            .with(body: bodyModel)
            .perform()
    }

    /// Create a new branch.
    /// - Parameters:
    ///   - branchName: name of new branch.
    ///   - ref: git ref (another branch name or commit sha) from where branch should be created.
    func createBranch(
        projectId: Int,
        branchName: String,
        ref: String
    ) -> AnyPublisher<Void, NetworkingError> {
        client
            .post("projects/\(projectId)/repository/branches")
            .with(queryItems: [
                "branch": branchName,
                "ref": ref,
            ])
            .perform()
    }
}
