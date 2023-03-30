//

import Foundation
import Guardian

public class UnitTestsResultsReporter {
    private let reporter: MergeRequestReporting

    public init(
        reporter: MergeRequestReporting
    ) {
        self.reporter = reporter
    }
}

// swiftformat:disable indent
extension UnitTestsResultsReporter: UnitTestsResultsReporting {
	public func failedToParseJUnit(error: Error, jobUrl: String) {
		let jobLogsText = "логи джобы"
		let jobLogsLinkText = "[\(jobLogsText)](\(jobUrl))"
		reporter.fail(
			"Придется заглянуть в \(jobLogsLinkText), " +
					"похоже упал билд или тесты, но я не смог распарсить причину 😢"
		)
		reporter.markdown("```log\nError decoding junit report: \(String(reflecting: error))\n```")
	}

	public func failedUnitTestsDetected(_ failures: [UnitTestsResultsChecker.Failure]) {
		let rows = failures.map {
			"""
			<tr>
			<td>
			<p>\($0.failure.file)</p>
			<p>\($0.testCaseName)</p>
			<pre>
			\($0.failure.message)
			</pre>
			</td>
			</tr>
			"""
		}.joined(separator: "\n")

		reporter.fail("Тесты упали :(")
		reporter.markdown("""
			### UnitTests Failed

			<table>
			<tr>
			<th>
			Failed Tests
			</th>
			</tr>
			\(rows)
			</table>
			""")
	}
}

// swiftformat:enable indent
