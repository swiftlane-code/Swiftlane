//

import Foundation

public struct RepositoryCompareResult: Decodable {
    public let commits: [CommitInfo]
    public let diffs: [FileDiff]
    public let compareTimeout: Bool
    public let compareSameRef: Bool
    public let webUrl: String?
}
