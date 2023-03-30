
import Foundation
import Guardian

// sourcery: AutoMockable
public protocol CommitsCheckerReporting {
    func reportSuccess()
    func reportFailsDetected(_ failsCommits: [String])
}

public class CommitsCheckerEnReporter {
    private let reporter: MergeRequestReporting

    public init(
        reporter: MergeRequestReporting
    ) {
        self.reporter = reporter
    }
}

extension CommitsCheckerEnReporter: CommitsCheckerReporting {
    public func reportSuccess() {
        reporter.success("The list of your comments has been checked. Everything is fine with you, go to the next window")
    }

    public func reportFailsDetected(_ failsCommits: [String]) {
        failsCommits
            .map {
                "ALARM! A commit loss has occurred: `\($0)`"
            }
            .forEach {
                reporter.fail($0)
            }
    }
}
