//

import Foundation
import Guardian

// swiftformat:disable indent
public class WarnigLimitsCheckerEnReporter {
	private let reporter: MergeRequestReporting

	public init(
		reporter: MergeRequestReporting
	) {
		self.reporter = reporter
	}

	public func fixAtLeastNWarnings(count: Int, inDirectory directory: String) -> String {
		"Comrade, it is necessary to get rid of **\(count)** warning's in \(directory)!"
	}

	public func countOfWarningIncreased(sameWarningArray: [SwiftLintViolation]) -> String {
		let rows = sameWarningArray.map {
			"\($0.file):\($0.line) | \($0.messageText) |"
		}
		return """
			#### New warning's ...

			| File | Warning |
			| ---- | ------- |
			\(rows.joined(separator: "\n"))
			"""
	}
}

// swiftformat:enable indent

extension WarnigLimitsCheckerEnReporter: WarningLimitsCheckerReporting {
    public func warningLimitsAreCorrect() {
        reporter.success("SwiftLint is happy")
    }

    public func warningLimitsHaveBeenLowered() {
        reporter.success("You are a golden man, thank you for bringing us closer to zero-warning!")
    }

    public func warningLimitsViolated(
        violations: [WarningLimitsChecker.Violation],
        newWarningsGroupedByMessage: [[SwiftLintViolation]]
    ) {
        violations.forEach {
            reporter.fail(
                fixAtLeastNWarnings(
                    count: $0.increase,
                    inDirectory: $0.directory
                )
            )
        }
        newWarningsGroupedByMessage.forEach {
            reporter.markdown(countOfWarningIncreased(sameWarningArray: $0))
        }
    }

    public func newWarningLimitsHaveBeenTracked() {
        reporter.success("Added warning limits for new targets.")
    }
}
