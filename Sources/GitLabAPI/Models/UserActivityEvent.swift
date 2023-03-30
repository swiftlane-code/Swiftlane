//

import Foundation

/// GitLab user acivity event.
public struct UserActivityEvent: Decodable {
    public let id: Int
    public let projectId: Int

    /// Type of the event.
    /// `"pushed to" / "approved" / "opened" / "pushed new" / "commented on" / "deleted" / "accepted"`
    /// `"accepted"` - user have merged a merge request
    public let actionName: String

    /// Date of event.
    public let createdAt: Date

    /// Author of event.
    public let author: Member

    /// Most common target is a merge request.
    public let targetId: Int?
    /// Most common target is a merge request.
    public let targetIid: Int?
    /// Most common target is a merge request.
    public let targetType: String?
    /// Most common target is a merge request.
    public let targetTitle: String?

    /// "push" event info.
    public let pushData: PushData?

    /// info about a merge request's note.
    public let note: NoteData?

    /// "push" event info.
    public struct PushData: Decodable {
        public let commitCount: Int?

        /// `"pushed"`
        public let action: String?

        /// `"branch"`
        public let refType: String?

        /// `"develop"`
        public let ref: String?

        public let commitTitle: String?
    }

    /// info about a merge request's note.
    public struct NoteData: Decodable {
        public let noteableId: Int
        public let noteableIid: Int
        /// `"MergeRequest"`
        public let noteableType: String
    }
}
