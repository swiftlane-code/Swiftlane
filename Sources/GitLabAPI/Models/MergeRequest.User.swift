//

import Foundation

public extension MergeRequest {
    struct User: Decodable {
        public let canMerge: Bool
    }
}
