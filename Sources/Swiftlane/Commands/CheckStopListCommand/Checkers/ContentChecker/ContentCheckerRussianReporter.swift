
import Foundation
import Guardian

// sourcery: AutoMockable
public protocol ContentCheckerReporting {
    func reportSuccess()
    func reportFailsDetected(_ fails: [ContentChecker.FileBadLinesInfo])
}

public class ContentCheckerRussianReporter {
    private let reporter: MergeRequestReporting
    private let rangesWelder: RangesWelding

    public init(
        reporter: MergeRequestReporting,
        rangesWelder: RangesWelding
    ) {
        self.reporter = reporter
        self.rangesWelder = rangesWelder
    }
}

extension ContentCheckerRussianReporter: ContentCheckerReporting {
    public func reportSuccess() {
        reporter.success("Всё в полном шоколаде. Запрещенных изменений в файлах не обнаружено.")
    }

    // swiftformat:disable indent
	public func reportFailsDetected(_ fails: [ContentChecker.FileBadLinesInfo]) {
		fails
			.map {
				"У вас в \($0.file) замечены запрещенные на территории GitLab'a изменения –  \($0.errorObject) в строках: "
				+ rangesWelder.weldRanges(from: $0.lines).joined(separator: ", ")
			}
			.forEach {
				reporter.fail($0)
			}
	}
	// swiftformat:enable indent
}
