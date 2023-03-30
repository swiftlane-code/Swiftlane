
import Foundation

// MARK: - MergeRequest

public struct MergeRequest: Decodable {
    public let id: Int
    public let iid: Int
    public let projectId: Int
    public let title: String
    public let description: String?
    public let state: String
    public let createdAt: Date
    public let updatedAt: Date
    public let targetBranch: String
    public let sourceBranch: String
    public let userNotesCount: Int?
    public let upvotes: Int
    public let downvotes: Int
    public let author: Member?
    public let assignees: [Member]
    public let assignee: Member?
    public let reviewers: [Member]
    public let sourceProjectId: Int
    public let targetProjectId: Int
    public let labels: [String]
    public let workInProgress: Bool
    public let mergeWhenPipelineSucceeds: Bool
    public let mergeStatus: String?
    public let sha: String?
    public let mergeCommitSha: String?
    public let squashCommitSha: String?
    public let discussionLocked: Bool?
    public let shouldRemoveSourceBranch: Bool?
    public let forceRemoveSourceBranch: Bool?
    public let webUrl: String?
    public let squash: Bool
    public let hasConflicts: Bool
    public let blockingDiscussionsResolved: Bool
    public let changesCount: String?
    public let user: MergeRequest.User?
    public let changes: [FileDiff]?
}
