//

import Foundation

public struct IssuesStatus: Codable {
    public let unmapped: Int
    public let toDo: Int
    public let inProgress: Int
    public let done: Int

    public var count: Int {
        unmapped + toDo + inProgress + done
    }

    public var percentDone: Int {
        Int(Double(done) / Double(count) * 100)
    }
}
