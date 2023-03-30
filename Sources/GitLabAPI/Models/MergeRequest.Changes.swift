//

import Foundation

public extension MergeRequest {
    struct Changes: Decodable {
        public init(changes: [FileDiff]?) {
            self.changes = changes
        }

        public let changes: [FileDiff]?
    }
}
