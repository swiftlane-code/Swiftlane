//

import Foundation
import Guardian
import SwiftlaneCore

public class TargetCoverageReporter {
    private let reporter: MergeRequestReporting

    public init(
        reporter: MergeRequestReporting
    ) {
        self.reporter = reporter
    }

    private func percent(
        from coverage: Double
    ) -> String {
        String(format: "%.1f", coverage * 100) + "%"
    }

    private func percentWithEmoji(
        from coverage: Double,
        emojiLevels: (
            red: Double,
            yellow: Double,
            green: Double
        ) = (0.2, 0.5, 0.7)
    ) -> String {
        let emoji: String = {
            switch coverage {
            case ..<emojiLevels.red:
                return "♦️"
            case ..<emojiLevels.yellow:
                return "🔸"
            case ..<emojiLevels.green:
                return "💚"
            default:
                return "🚀"
            }
        }()

        return percent(from: coverage) + "  " + emoji
    }

    private func kilo(_ int: Int) -> String {
        if int < 1000 {
            return String(int)
        }
        let number = String(format: "%.1f", Double(int) / 1000)
        return number + "k"
    }
}

// swiftformat:disable indent
extension TargetCoverageReporter: TargetCoverageReporting {
	public func reportAllTargetsCoverage(targets: [CalculatedTargetCoverage]) {
		let rows = targets
			.sorted { lhs, rhs in
				lhs.lineCoverage > rhs.lineCoverage
			}
			.map {
				"""
				\($0.targetName) | \
				\(percentWithEmoji(from: $0.lineCoverage)) | \
				\(($0.limitInt.map { "\($0)%" }) ?? " ") | \
				\(kilo($0.coveredLines)) / \(kilo($0.executableLines)) |
				"""
			}

		let msg = """
			#### Code Coverage

			| Target | Coverage | Limit | Covered lines / Executable lines |
			| ------ | -------- | ----- | -------------------------------- |
			\(rows.joined(separator: "\n"))
			"""

		reporter.markdown(msg)
	}

	public func reportCoverageLimitsSuccess() {
		reporter.success("Limits Code Coverage by targets is ok")
	}

	public func reportCoverageLimitsCheckFailed(violation: TargetsCoverageLimitChecker.Violation) {
		reporter.fail(
			"Code Coverage of target \(violation.targetName) (\(percent(from: violation.actualCoverage))) " +
			" less than \(percent(from: violation.minCoverage))"
		)
	}
}

// swiftformat:enable indent
