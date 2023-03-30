//

import Combine
import Foundation
import Networking

// sourcery: AutoMockable
public protocol GitLabAPIClientProtocol {
    // MARK: - GitLabAPIClient+ApprovalRules

    /// All approval rules (full info) of a project.
    func projectApprovalRules(projectId: Int) -> AnyPublisher<[MergeRequestApprovalRule], NetworkingError>

    /// All approval rules (full info) of a Merge Request.
    func mergeRequestApprovalRulesAll(projectId: Int, mergeRequestIid: Int)
        -> AnyPublisher<[MergeRequestApprovalRule], NetworkingError>

    /// Information about current state of approval rules of a Merge Request.
    /// `approvalRulesLeft` containts only partial info (id and name).
    func mergeRequestApprovalRulesLeft(projectId: Int, mergeRequestIid: Int)
        -> AnyPublisher<MergeRequestApprovals, NetworkingError>

    // MARK: - GitLabAPIClient+MergeRequests

    /// Load Merge Request info.
    /// - Parameters:
    ///   - projectId: gitlab project id.
    ///   - mergeRequestIid: merge request iid.
    ///   - loadChanges: if merge request diff should be present in the response.
    func mergeRequest(projectId: Int, mergeRequestIid: Int, loadChanges: Bool)
        -> AnyPublisher<MergeRequest, NetworkingError>

    /// Merge Request Commits.
    func mergeRequestCommits(
        projectId: Int,
        mergeRequestIid: Int
    ) -> AnyPublisher<[MergeRequest.Commit], NetworkingError>

    /// Merge Request Changes.
    func mergeRequestChanges(projectId: Int, mergeRequestIid: Int) -> AnyPublisher<MergeRequest.Changes, NetworkingError>

    /// Load Merge Requests based on filters.
    /// - Parameters:
    ///   - state: load only request in that state.
    ///   - space: GitLab space (group or project).
    ///   - createdAfter: load only request created after that date.
    ///   - authorId: load only requests created by that author.
    func mergeRequests(inState state: MergeRequest.State, space: GitLab.Space, createdAfter: Date?, authorId: Int?)
        -> AnyPublisher<[MergeRequest], NetworkingError>

    /// Load notes (comments) of a merge request.
    func mergeRequestNotes(
        projectId: Int,
        mergeRequestIid: Int,
        orderBy: GitLabAPIClient.MergeRequestNotesOrderBy,
        sorting: GitLabAPIClient.MergeRequestNotesSorting
    ) -> AnyPublisher<[MergeRequest.Note], NetworkingError>

    // MARK: - GitLabAPIClient+Repository

    /// Load file content.
    /// - Parameters:
    ///   - path: file path relative to repo root.
    ///   - ref: git ref (branch name or commit sha).
    func loadRepositoryFile(path: String, projectId: Int, ref: String) -> AnyPublisher<FileContent, NetworkingError>

    /// Load Diff between two refs (the same diff as if we create a merge request `source -> target`).
    /// - Parameters:
    ///   - projectId: gitlab project (repo) id.
    ///   - source: The commit SHA or branch name.
    ///   - target: The commit SHA or branch name.
    func repositoryDiff(projectId: Int, source: String, target: String)
        -> AnyPublisher<RepositoryCompareResult, NetworkingError>

    // MARK: - GitLabAPIClient+EditRepository

    /// Update file contents.
    func updateRepositoryFile(path: String, projectId: Int, bodyModel: UpdateFileContent)
        -> AnyPublisher<Void, NetworkingError>

    /// Create a new branch.
    /// - Parameters:
    ///   - branchName: name of new branch.
    ///   - ref: git ref (another branch name or commit sha) from where branch should be created.
    func createBranch(projectId: Int, branchName: String, ref: String) -> AnyPublisher<Void, NetworkingError>

    // MARK: - GitLabAPIClient+Users

    func userActivityEvents(userId: Int, after: Date, page: Int, perPage: Int)
        -> AnyPublisher<[UserActivityEvent], NetworkingError>

    func groupMembers(group: GitLab.Group) -> AnyPublisher<[Member], NetworkingError>

    func groupDetails(group: GitLab.Group) -> AnyPublisher<Group, NetworkingError>

    // MARK: - GitLabAPIClient+EditMergeRequest

    /// Set an assignee to a merge request.
    /// - Parameters:
    ///   - assigneeId: gitlab user id or `nil` to clean up assignee.
    func setMergeRequest(projectId: Int, mergeRequestIid: Int, assigneeId: Int?)
        -> AnyPublisher<MergeRequest, NetworkingError>

    /// Change labels of a merge request.
    func setMergeRequest(projectId: Int, mergeRequestIid: Int, addLabels: [String], removeLabels: [String])
        -> AnyPublisher<MergeRequest, NetworkingError>

    /// Set labels of a merge request.
    /// - Parameters:
    ///   - labels: list of labels a merge request should have.
    func setMergeRequest(projectId: Int, mergeRequestIid: Int, labels: [String])
        -> AnyPublisher<MergeRequest, NetworkingError>

    /// Set reviewers of a merge request.
    /// - Parameters:
    ///   - projectId: gitlab project id.
    ///   - mergeRequestIid: iid of a merge request.
    ///   - reviewersIds: list of user ids to set as reviewers.
    func setMergeRequest(projectId: Int, mergeRequestIid: Int, reviewersIds: [Int])
        -> AnyPublisher<MergeRequest, NetworkingError>

    /// Create a note (comments) for a merge request.
    /// - Parameters:
    ///   - mergeRequestIid: iid merge request'a.
    func createMergeRequestNote(projectId: Int, mergeRequestIid: Int, body: String)
        -> AnyPublisher<MergeRequest.Note, NetworkingError>

    /// Change a note of a merge request.
    func setMergeRequestNote(projectId: Int, mergeRequestIid: Int, noteId: Int, body: String)
        -> AnyPublisher<MergeRequest.Note, NetworkingError>

    /// Delete a note of a merge request.
    func deleteMergeRequestNote(projectId: Int, mergeRequestIid: Int, noteId: Int) -> AnyPublisher<Void, NetworkingError>

    // MARK: - GitLabAPIClient+Pipelines

    /// Load pipeline info.
    func pipeline(projectId: Int, pipelineId: Int) -> AnyPublisher<Pipeline, NetworkingError>

    // MARK: - GitLabAPIClient+EditPipelines

    func createPipeline(projectId: Int, bodyModel: CreatePipeline) -> AnyPublisher<Pipeline, NetworkingError>

    // MARK: - Packages

    /// Recursively load `listPackages` for all available pages.
    /// - Parameters:
    ///   - name: find packages by name, name matching is not strict.
    ///   - loadAtLeast: stop loading pages when total packages loaded >= `loadAtLeast`.
    ///   - baseRequest: request model to be used as a base to load pages.
    /// - Returns: array of all packages.
    func allPackages(
        space: GitLab.Space,
        loadAtLeast: Int?,
        baseRequest: PackagesListRequest
    ) -> AnyPublisher<[Package], NetworkingError>

    func listPackages(
        space: GitLab.Space,
        request: PackagesListRequest
    ) -> AnyPublisher<[Package], NetworkingError>

    func downloadPackage(
        space: GitLab.Space,
        name: String,
        version: String,
        fileName: String,
        timeout: TimeInterval
    ) -> AnyPublisher<ProgressOrResult<NetworkingProgress, Data>, NetworkingError>

    func uploadPackage(
        space: GitLab.Space,
        name: String,
        version: String,
        fileName: String,
        data: Data,
        timeout: TimeInterval
    ) -> AnyPublisher<ProgressOrResult<NetworkingProgress, PackageUploadResult>, NetworkingError>

    func deletePackage(
        space: GitLab.Space,
        id: Int
    ) -> AnyPublisher<Void, NetworkingError>
}
