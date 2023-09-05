//

import Foundation
import Git
import Guardian
import SwiftlaneCore

public final class GuardianCheckAuthorTask {
    private let logger: Logging
    private let reporter: MergeRequestReporting
    private let mergeRequestAuthorChecker: MergeRequestAuthorChecking
    private let gitlabCIEnvironmentReader: GitLabCIEnvironmentReading

    public init(
        logger: Logging,
        mergeRequestReporter: MergeRequestReporting,
        mergeRequestAuthorChecker: MergeRequestAuthorChecking,
        gitlabCIEnvironmentReader: GitLabCIEnvironmentReading
    ) {
        self.logger = logger
        self.reporter = mergeRequestReporter
        self.mergeRequestAuthorChecker = mergeRequestAuthorChecker
        self.gitlabCIEnvironmentReader = gitlabCIEnvironmentReader
    }

    public func run() throws {
        try mergeRequestAuthorChecker.check()
    }
}
