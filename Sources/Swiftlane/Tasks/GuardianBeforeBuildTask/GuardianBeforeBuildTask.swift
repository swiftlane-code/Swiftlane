//

import Foundation
import Git
import Guardian
import SwiftlaneCore

public final class GuardianBeforeBuildTask {
    private let logger: Logging
    private let reporter: MergeRequestReporting
    private let warningLimitsChecker: WarningLimitsChecking
    private let warningLimitsUntrackedChecker: WarningLimitsUntrackedChecking
    private let expiredToDoChecker: ExpiringToDoChecking
    private let stubDeclarationChecker: StubDeclarationChecking
    private let filePathChecker: AllowedFilePathChecking

    private let config: WarningLimitsConfig
    private let issueKeySearcher: JiraIssueKeySearching

    public init(
        logger: Logging,
        mergeRequestReporter: MergeRequestReporting,
        warningLimitsChecker: WarningLimitsChecking,
        warningLimitsUntrackedChecker: WarningLimitsUntrackedChecking,
        expiredToDoChecker: ExpiringToDoChecking,
        stubDeclarationChecker: StubDeclarationChecking,
        filePathChecker: AllowedFilePathChecking,
        config: WarningLimitsConfig,
        issueKeySearcher: JiraIssueKeySearching
    ) {
        self.logger = logger
        self.reporter = mergeRequestReporter
        self.warningLimitsChecker = warningLimitsChecker
        self.warningLimitsUntrackedChecker = warningLimitsUntrackedChecker
        self.expiredToDoChecker = expiredToDoChecker
        self.stubDeclarationChecker = stubDeclarationChecker
        self.filePathChecker = filePathChecker
        self.config = config
        self.issueKeySearcher = issueKeySearcher
    }

    private func validateWarningLimits() throws {
        let jiraTask = try issueKeySearcher.searchIssueKeys().first.unwrap()

        let warningLimitsCheckerConfig = WarningLimitsCheckerConfig(
            projectDir: config.projectDir,
            swiftlintConfigPath: config.swiftlintConfigPath,
            trackingPushRemoteName: config.remoteName,
            trackingNewFoldersCommitMessage: jiraTask + " " + config.trackingNewFoldersCommitMessage,
            loweringWarningLimitsCommitMessage: jiraTask + " " + config.loweringWarningLimitsCommitMessage,
            committeeName: config.committeeName,
            committeeEmail: config.committeeEmail,
            testableTargetsListFile: config.testableTargetsListFile
        )

        try warningLimitsUntrackedChecker.checkUntrackedLimits(config: warningLimitsCheckerConfig)

        try warningLimitsChecker.checkLimits(config: warningLimitsCheckerConfig)
    }

    public func run() throws {
        try expiredToDoChecker.checkExpiringToDos()
        try validateWarningLimits()
        try stubDeclarationChecker.checkMocksDeclarations()
        try filePathChecker.checkFilesPaths()

        if !reporter.hasFails() {
            reporter.success("All pre-build checks passed.")
        }
    }
}
