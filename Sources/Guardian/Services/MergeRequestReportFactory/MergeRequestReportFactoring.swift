//

import Foundation

// sourcery: AutoMockable
public protocol MergeRequestReportFactoring {
    func reportBody(
        fails: [String],
        warns: [String],
        messages: [String],
        markdowns: [String],
        successes: [String],
        invisibleMark: String,
        commitSHA: String
    ) -> String
}
