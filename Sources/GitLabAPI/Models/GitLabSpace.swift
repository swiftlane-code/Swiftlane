//

import Foundation

public enum GitLab {
    public struct Group {
        public let id: Int

        public init(id: Int) {
            self.id = id
        }
    }

    public struct Project {
        public let id: Int

        public init(id: Int) {
            self.id = id
        }
    }

    /// GitLab space.
    public enum Space {
        case group(id: Int)
        case project(id: Int)

        /// ! Caution: Some API methods do not support this.
        case everywhere

        func apiPath(suffix: String) -> String {
            switch self {
            case let .group(id):
                return "groups/\(id)/" + suffix
            case let .project(id):
                return "projects/\(id)/" + suffix
            case .everywhere:
                return suffix
            }
        }
    }
}
