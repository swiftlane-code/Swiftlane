//

import Foundation
import Guardian

public class ChangesCoverageReporter {
    private let reporter: MergeRequestReporting

    public init(
        reporter: MergeRequestReporting
    ) {
        self.reporter = reporter
    }
}

// swiftformat:disable indent
extension ChangesCoverageReporter: ChangesCoverageReporting {
	public func reportSuccess() {
		reporter.success("Code Coverage is ok.")
	}

	public func reportCheckIsDisabledForSourceBranch(sourceBranch: String) {
		reporter.message("Limits of Code Coverage are not checked for source branch: `\(sourceBranch)`.")
	}

	public func reportCheckIsDisabledForTargetBranch(targetBranch: String) {
		reporter.message("Limits of Code Coverage are not checked for target branch: `\(targetBranch)`.")
	}

	public func reportViolation(_ violation: ChangesCoverageLimitChecker.Violation, limit: Int) {
		func percent(from double: Double) -> String {
			"\(Int(round(double * 100)))%"
		}

		reporter.fail(
			"Code Coverage of changes is *(\(percent(from: violation.coverageOfChangedLines)))* " +
			"less than the limit *\(limit)%* for file \(violation.file)"
		)
	}
}

// swiftformat:enable indent
