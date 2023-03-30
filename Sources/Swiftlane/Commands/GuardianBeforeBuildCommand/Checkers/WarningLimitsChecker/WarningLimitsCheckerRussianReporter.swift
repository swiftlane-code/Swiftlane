//

import Foundation
import Guardian

// swiftformat:disable indent
public class WarnigLimitsCheckerRussianReporter {
	private let reporter: MergeRequestReporting

	public init(
		reporter: MergeRequestReporting
	) {
		self.reporter = reporter
	}

	public func fixAtLeastNWarnings(count: Int, inDirectory directory: String) -> String {
		"Товарищъ, необходимо избавиться от **\(count)** warning'\(count == 1 ? "а" : "ов") в \(directory)!"
	}

	public func countOfWarningIncreased(sameWarningArray: [SwiftLintViolation]) -> String {
		let rows = sameWarningArray.map {
			"\($0.file):\($0.line) | \($0.messageText) |"
		}
		return """
			#### Вот таких warning'ов раньше было меньше...

			| Файл | Warning |
			| ---- | ------- |
			\(rows.joined(separator: "\n"))
			"""
	}
}

// swiftformat:enable indent

extension WarnigLimitsCheckerRussianReporter: WarningLimitsCheckerReporting {
    public func warningLimitsAreCorrect() {
        reporter.success("SwiftLint доволен")
    }

    public func warningLimitsHaveBeenLowered() {
        reporter.success("Золотой вы человек, спасибо за то, что приближаете нас к zero-warning!")
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
        reporter.success("Добавлены warning лимиты для новых таргетов.")
    }
}
