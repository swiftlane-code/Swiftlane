
import Foundation
import Guardian

// sourcery: AutoMockable
public protocol ContentCheckerReporting {
    func reportSuccess()
    func reportFailsDetected(_ fails: [ContentChecker.FileBadLinesInfo])
}

public class ContentCheckerEnReporter {
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

extension ContentCheckerEnReporter: ContentCheckerReporting {
    public func reportSuccess() {
        reporter.success("Everything is in full chocolate. No prohibited changes were found in the files.")
    }

    // swiftformat:disable indent
	public func reportFailsDetected(_ fails: [ContentChecker.FileBadLinesInfo]) {
		fails
			.map {
				"In \($0.file) changes prohibited on the territory of GitLab have been noticed –  \($0.errorObject) in strings: "
				+ rangesWelder.weldRanges(from: $0.lines).joined(separator: ", ")
			}
			.forEach {
				reporter.fail($0)
			}
	}
	// swiftformat:enable indent
}
