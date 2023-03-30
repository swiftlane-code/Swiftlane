//

import Foundation

// sourcery: AutoMockable
public protocol WarningLimitsCheckerReporting {
    func warningLimitsAreCorrect()
    func warningLimitsHaveBeenLowered()
    func warningLimitsViolated(
        violations: [WarningLimitsChecker.Violation],
        newWarningsGroupedByMessage: [[SwiftLintViolation]]
    )
    func newWarningLimitsHaveBeenTracked()
}
