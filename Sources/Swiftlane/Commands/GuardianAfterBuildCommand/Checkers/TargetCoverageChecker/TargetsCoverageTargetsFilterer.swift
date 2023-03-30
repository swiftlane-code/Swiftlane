//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol TargetsCoverageTargetsFiltering {
    func filterTargets(
        report: XCCOVCoverageReport,
        allowedProductNameSuffixes: [String],
        excludeTargetsNames: [StringMatcher]
    ) -> [XCCOVTargetCoverage]
}

public class TargetsCoverageTargetsFilterer {
    public init() {}
}

extension TargetsCoverageTargetsFilterer: TargetsCoverageTargetsFiltering {
    public func filterTargets(
        report: XCCOVCoverageReport,
        allowedProductNameSuffixes: [String],
        excludeTargetsNames: [StringMatcher]
    ) -> [XCCOVTargetCoverage] {
        report.targets
            .filter { target in
                allowedProductNameSuffixes.contains {
                    target.name.hasSuffix($0)
                }
            }
            .filter { target in
                !excludeTargetsNames.isMatching(string: target.realTargetName)
            }
    }
}
