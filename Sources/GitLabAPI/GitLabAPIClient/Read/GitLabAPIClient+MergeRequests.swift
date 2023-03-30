//

import Combine
import Foundation
import Networking

/// Working with merge requests.
public extension GitLabAPIClient {
    /// Load Merge Request info.
    /// - Parameters:
    ///   - projectId: gitlab project id.
    ///   - mergeRequestIid: merge request iid.
    ///   - loadChanges: if merge request diff should be present in the response.
    func mergeRequest(
        projectId: Int,
        mergeRequestIid: Int,
        loadChanges: Bool
    ) -> AnyPublisher<MergeRequest, NetworkingError> {
        client
            .get("projects/\(projectId)/merge_requests/\(mergeRequestIid)" + (loadChanges ? "/changes" : ""))
            .with(queryItems: ["access_raw_diffs": true])
            .perform()
    }

    /// Merge Request Commits.
    func mergeRequestCommits(
        projectId: Int,
        mergeRequestIid: Int
    ) -> AnyPublisher<[MergeRequest.Commit], NetworkingError> {
        client
            .get("projects/\(projectId)/merge_requests/\(mergeRequestIid)/commits")
            .perform()
    }

    /// Merge Request Changes.
    func mergeRequestChanges(
        projectId: Int,
        mergeRequestIid: Int
    ) -> AnyPublisher<MergeRequest.Changes, NetworkingError> {
        client
            .get("projects/\(projectId)/merge_requests/\(mergeRequestIid)/changes")
            .with(queryItems: ["access_raw_diffs": true])
            .perform()
    }

    /// Load Merge Requests based on filters.
    /// - Parameters:
    ///   - state: load only request in that state.
    ///   - space: GitLab space (group or project).
    ///   - createdAfter: load only request created after that date.
    ///   - authorId: load only requests created by that author.
    func mergeRequests(
        inState state: MergeRequest.State,
        space: GitLab.Space,
        createdAfter: Date? = nil,
        authorId: Int? = nil
    ) -> AnyPublisher<[MergeRequest], NetworkingError> {
        client
            .get(space.apiPath(suffix: "merge_requests"))
            .with(
                queryItems: [
                    "state": state.rawValue,
                    "created_after": createdAfter?.shortISO8601String,
                    "scope": "all",
                    "author_id": authorId,
                    /// Gitlab API: `100` is max value for `per_page`.
                    "per_page": 100,
                ].compactMapValues { $0 }
            )
            .perform()
    }

    /// Load notes (comments) of a merge request.
    func mergeRequestNotes(
        projectId: Int,
        mergeRequestIid: Int,
        orderBy: MergeRequestNotesOrderBy,
        sorting: MergeRequestNotesSorting
    ) -> AnyPublisher<[MergeRequest.Note], NetworkingError> {
        client
            .get("/projects/\(projectId)/merge_requests/\(mergeRequestIid)/notes")
            .with(queryItems: [
                "per_page": 100,
                "order_by": orderBy.rawValue,
                "sort": sorting.rawValue,
            ])
            .perform()
    }
}

public extension GitLabAPIClient {
    enum MergeRequestNotesSorting: String {
        case ascending = "asc"
        case descending = "desc"
    }

    enum MergeRequestNotesOrderBy: String {
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
