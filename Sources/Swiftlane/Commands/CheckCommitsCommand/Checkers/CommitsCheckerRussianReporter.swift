
import Foundation
import Guardian

// sourcery: AutoMockable
public protocol CommitsCheckerReporting {
    func reportSuccess()
    func reportFailsDetected(_ failsCommits: [String])
}

public class CommitsCheckerRussianReporter {
    private let reporter: MergeRequestReporting

    public init(
        reporter: MergeRequestReporting
    ) {
        self.reporter = reporter
    }
}

extension CommitsCheckerRussianReporter: CommitsCheckerReporting {
    public func reportSuccess() {
        reporter.success("Список ваших коммитов проверен. У вас всё впорядке, проходите к следующему окошку")
    }

    public func reportFailsDetected(_ failsCommits: [String]) {
        failsCommits
            .map {
                "ALARM! Произошла потеря коммита: `\($0)`"
            }
            .forEach {
                reporter.fail($0)
            }
    }
}
