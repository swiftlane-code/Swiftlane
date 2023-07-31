//

import Foundation
import Git
import Guardian
import SwiftlaneCore

public final class GuardianBeforeBuildTask: GuardianBaseTask {
    private let reporter: MergeRequestReporting
    private let warningLimitsChecker: WarningLimitsChecking
    private let warningLimitsUntrackedChecker: WarningLimitsUntrackedChecking
    private let expiredToDoChecker: ExpiringToDoChecking
    private let stubDeclarationChecker: StubDeclarationChecking
    private let filePathChecker: AllowedFilePathChecking

    private let config: WarningLimitsConfig
    private let gitlabCIEnvironmentReader: GitLabCIEnvironmentReading

    public init(
        logger: Logging,
        mergeRequestReporter: MergeRequestReporting,
        warningLimitsChecker: WarningLimitsChecking,
        warningLimitsUntrackedChecker: WarningLimitsUntrackedChecking,
        expiredToDoChecker: ExpiringToDoChecking,
        stubDeclarationChecker: StubDeclarationChecking,
        filePathChecker: AllowedFilePathChecking,
        config: WarningLimitsConfig,
        gitlabCIEnvironmentReader: GitLabCIEnvironmentReading
    ) {
        reporter = mergeRequestReporter
        self.warningLimitsChecker = warningLimitsChecker
        self.warningLimitsUntrackedChecker = warningLimitsUntrackedChecker
        self.expiredToDoChecker = expiredToDoChecker
        self.stubDeclarationChecker = stubDeclarationChecker
        self.filePathChecker = filePathChecker
        self.config = config
        self.gitlabCIEnvironmentReader = gitlabCIEnvironmentReader
        super.init(reporter: reporter, logger: logger)
    }

    private func jiraTask() throws -> String {
        let regex = try NSRegularExpression(pattern: config.jiraTaskRegex)
        let sourceBranch = try gitlabCIEnvironmentReader.string(.CI_MERGE_REQUEST_SOURCE_BRANCH_NAME)
        let match = regex.firstMatchString(in: sourceBranch)
        return try match.unwrap(
            errorDescription: "Unable to get jira task id from source branch name \"\(sourceBranch)\""
        )
    }

    private func verifyExpiredToDos() throws {
        try expiredToDoChecker.checkExpiringToDos()
    }

    private func validateWarningLimits() throws {
        let jiraTask = try jiraTask()

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

    private func checkMocksDeclarations() throws {
        try stubDeclarationChecker.checkMocksDeclarations()
    }

    override public func executeChecksOnly() throws {
        try verifyExpiredToDos()
        try validateWarningLimits()
        try checkMocksDeclarations()
        try filePathChecker.checkFilesPaths()

        if !reporter.hasFails() {
            reporter.markdown("#### Running tests...")
        }
    }
}
