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
		reporter.success("Code Coverage изменений в порядке.")
	}

	public func reportCheckIsDisabledForSourceBranch(sourceBranch: String) {
		reporter.message("Лимиты на Code Coverage изменений не проверяются для MR-ов из ветки `\(sourceBranch)`.")
	}

	public func reportCheckIsDisabledForTargetBranch(targetBranch: String) {
		reporter.message("Лимиты на Code Coverage изменений не проверяются для MR-ов в ветку `\(targetBranch)`.")
	}

	public func reportViolation(_ violation: ChangesCoverageLimitChecker.Violation, limit: Int) {
		func percent(from double: Double) -> String {
			"\(Int(round(double * 100)))%"
		}

		reporter.fail(
			"Code Coverage изменений *(\(percent(from: violation.coverageOfChangedLines)))* " +
			"меньше лимита *\(limit)%* в файле \(violation.file)"
		)
	}
}

// swiftformat:enable indent
