//

import Combine
import Foundation
import Networking

/// Working with files in a repository.
public extension GitLabAPIClient {
    /// Load file content.
    /// - Parameters:
    ///   - path: file path relative to repo root.
    ///   - ref: git ref (branch name or commit sha).
    func loadRepositoryFile(
        path: String,
        projectId: Int,
        ref: String = "master"
    ) -> AnyPublisher<FileContent, NetworkingError> {
        let escapedPath = path.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? path
        return client
            .get("projects/\(projectId)/repository/files/\(escapedPath)")
            .with(queryItems: ["ref": ref])
            .perform()
    }

    /// Load Diff between two refs (the same diff as if we create a merge request `source -> target`).
    /// - Parameters:
    ///   - projectId: gitlab project (repo) id.
    ///   - source: The commit SHA or branch name.
    ///   - target: The commit SHA or branch name.
    func repositoryDiff(
        projectId: Int,
        source: String,
        target: String
    ) -> AnyPublisher<RepositoryCompareResult, NetworkingError> {
        client
            .get("projects/\(projectId)/repository/compare")
            .with(queryItems: [
                "from": target,
                "to": source,
            ])
            .perform()
    }
}
