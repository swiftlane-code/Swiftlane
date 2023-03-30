//

import Combine
import Foundation
import Networking

/// Mofifying merge requests.
public extension GitLabAPIClient {
    /// Set an assignee to a merge request.
    /// - Parameters:
    ///   - assigneeId: gitlab user id or `nil` to clean up assignee.
    func setMergeRequest(
        projectId: Int,
        mergeRequestIid: Int,
        assigneeId: Int?
    ) -> AnyPublisher<MergeRequest, NetworkingError> {
        client
            .put("projects/\(projectId)/merge_requests/\(mergeRequestIid)")
            .with(body: [
                "assignee_ids": [assigneeId].compactMap { $0 },
            ])
            .perform()
    }

    /// Change labels of a merge request.
    func setMergeRequest(
        projectId: Int,
        mergeRequestIid: Int,
        addLabels: [String],
        removeLabels: [String]
    ) -> AnyPublisher<MergeRequest, NetworkingError> {
        client
            .put("projects/\(projectId)/merge_requests/\(mergeRequestIid)")
            .with(body: [
                "add_labels": addLabels.joined(separator: ","),
                "remove_labels": removeLabels.joined(separator: ","),
            ])
            .perform()
    }

    /// Set labels of a merge request.
    /// - Parameters:
    ///   - labels: list of labels a merge request should have.
    func setMergeRequest(
        projectId: Int,
        mergeRequestIid: Int,
        labels: [String]
    ) -> AnyPublisher<MergeRequest, NetworkingError> {
        mergeRequest(projectId: projectId, mergeRequestIid: mergeRequestIid, loadChanges: false)
            .flatMap { [self] mrData -> AnyPublisher<MergeRequest, NetworkingError> in
                let currentLabels = Set(mrData.labels)
                let targetLabels = Set(labels)
                let removeLabels = currentLabels.subtracting(targetLabels).sorted()
                let addLabels = targetLabels.subtracting(currentLabels).sorted()

                return setMergeRequest(
                    projectId: projectId,
                    mergeRequestIid: mergeRequestIid,
                    addLabels: addLabels,
                    removeLabels: removeLabels
                )
            }
            .eraseToAnyPublisher()
    }

    /// Set reviewers of a merge request.
    /// - Parameters:
    ///   - projectId: gitlab project id.
    ///   - mergeRequestIid: iid of a merge request.
    ///   - reviewersIds: list of user ids to set as reviewers.
    func setMergeRequest(
        projectId: Int,
        mergeRequestIid: Int,
        reviewersIds: [Int]
    ) -> AnyPublisher<MergeRequest, NetworkingError> {
        client
            .put("projects/\(projectId)/merge_requests/\(mergeRequestIid)")
            .with(body: [
                "reviewer_ids": reviewersIds,
            ])
            .perform()
    }

    /// Create a note (comments) for a merge request.
    /// - Parameters:
    ///   - mergeRequestIid: iid merge request'a.
    func createMergeRequestNote(
        projectId: Int,
        mergeRequestIid: Int,
        body: String
    ) -> AnyPublisher<MergeRequest.Note, NetworkingError> {
        client
            .post("/projects/\(projectId)/merge_requests/\(mergeRequestIid)/notes")
            .with(body: [
                "body": body,
            ])
            .perform()
    }

    /// Change a note of a merge request.
    func setMergeRequestNote(
        projectId: Int,
        mergeRequestIid: Int,
        noteId: Int,
        body: String
    ) -> AnyPublisher<MergeRequest.Note, NetworkingError> {
        client
            .put("/projects/\(projectId)/merge_requests/\(mergeRequestIid)/notes/\(noteId)")
            .with(body: [
                "body": body,
            ])
            .perform()
    }

    /// Delete a note of a merge request.
    func deleteMergeRequestNote(
        projectId: Int,
        mergeRequestIid: Int,
        noteId: Int
    ) -> AnyPublisher<Void, NetworkingError> {
        client
            .delete("/projects/\(projectId)/merge_requests/\(mergeRequestIid)/notes/\(noteId)")
            .perform()
    }
}
