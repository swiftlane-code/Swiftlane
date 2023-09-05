//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol TargetCoverageReporting {
    func reportAllTargetsCoverage(targets: [CalculatedTargetCoverage])
    func reportCoverageLimitsSuccess()
    func reportCoverageLimitsCheckFailed(violation: TargetsCoverageLimitChecker.Violation)
}
