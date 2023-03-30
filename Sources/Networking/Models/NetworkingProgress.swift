//

import Foundation

public struct NetworkingProgress: Hashable, Comparable, Codable {
    /// Correct value is guarantied.
    public let fractionCompleted: Double
    /// Correct value is NOT guarantied.
    public let completedBytes: Int64
    /// Correct value is NOT guarantied.
    public let totalBytes: Int64

    public static func < (lhs: NetworkingProgress, rhs: NetworkingProgress) -> Bool {
        lhs.fractionCompleted < rhs.fractionCompleted
    }
}
