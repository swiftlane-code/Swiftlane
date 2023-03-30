
import Foundation
import Guardian
import SwiftlaneCore

public final class CheckCommitsTask {
    private let checker: CommitsChecking
    private let reporter: MergeRequestReporting

    public init(
        checker: CommitsChecking,
        reporter: MergeRequestReporting
    ) {
        self.checker = checker
        self.reporter = reporter
    }

    public func run() throws {
        try checker.checkCommits()

        try reporter.createOrUpdateReport()
    }
}
