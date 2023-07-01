//

import Foundation

// sourcery: AutoMockable
public protocol ChangesCoverageReporting {
    func reportSuccess()
    func reportCheckIsDisabledForSourceBranch(sourceBranch: String)
    func reportCheckIsDisabledForTargetBranch(targetBranch: String)
    func reportViolation(_ violation: ChangesCoverageLimitChecker.Violation, limit: Int)
}
