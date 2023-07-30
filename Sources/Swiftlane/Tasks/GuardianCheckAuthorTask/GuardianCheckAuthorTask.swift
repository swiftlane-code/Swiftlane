//

import Foundation
import Git
import Guardian
import SwiftlaneCore

public final class GuardianCheckAuthorTask: GuardianBaseTask {
    private let reporter: MergeRequestReporting
    private let mergeRequestAuthorChecker: MergeRequestAuthorChecking
    private let gitlabCIEnvironmentReader: GitLabCIEnvironmentReading

    public init(
        logger: Logging,
        mergeRequestReporter: MergeRequestReporting,
        mergeRequestAuthorChecker: MergeRequestAuthorChecking,
        gitlabCIEnvironmentReader: GitLabCIEnvironmentReading
    ) {
        reporter = mergeRequestReporter
        self.mergeRequestAuthorChecker = mergeRequestAuthorChecker
        self.gitlabCIEnvironmentReader = gitlabCIEnvironmentReader
        super.init(reporter: reporter, logger: logger)
    }

    override public func executeChecksOnly() throws {
        try mergeRequestAuthorChecker.check()
    }
}
