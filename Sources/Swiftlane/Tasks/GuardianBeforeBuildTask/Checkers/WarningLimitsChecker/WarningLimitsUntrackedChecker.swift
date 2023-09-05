//

import Foundation
import Git
import Guardian
import SwiftlaneCore

private typealias WarningState = (
    directory: String,
    new: [SwiftLintViolation]
)

public protocol WarningLimitsUntrackedChecking {
    func checkUntrackedLimits(config: WarningLimitsCheckerConfig) throws
}

/// Creates known warnings json files for targets which doesn't have one yet.
public class WarningLimitsUntrackedChecker {
    private let swiftLint: SwiftLintProtocol
    private let filesManager: FSManaging
    private let warningsStorage: WarningsStoraging
    private let logger: Logging
    private let git: GitProtocol
    private let reporter: WarningLimitsCheckerReporting
    private let slather: SlatherServicing
    private let gitlabCIEnvironmentReader: GitLabCIEnvironmentReading

    public init(
        swiftLint: SwiftLintProtocol,
        filesManager: FSManaging,
        warningsStorage: WarningsStoraging,
        logger: Logging,
        git: GitProtocol,
        reporter: WarningLimitsCheckerReporting,
        slather: SlatherServicing,
        gitlabCIEnvironmentReader: GitLabCIEnvironmentReading
    ) {
        self.swiftLint = swiftLint
        self.filesManager = filesManager
        self.warningsStorage = warningsStorage
        self.logger = logger
        self.git = git
        self.reporter = reporter
        self.slather = slather
        self.gitlabCIEnvironmentReader = gitlabCIEnvironmentReader
    }
}

extension WarningLimitsUntrackedChecker: WarningLimitsUntrackedChecking {
    public func checkUntrackedLimits(config: WarningLimitsCheckerConfig) throws {
        let trackedDirectories = try warningsStorage.readListOfDirectories()

        let allDirectories = try slather.readTestableTargetsNames(
            filePath: config.testableTargetsListFile.makeAbsoluteIfIsnt(relativeTo: config.projectDir)
        )
        let untrackedDirectories = Set(allDirectories).subtracting(Set(trackedDirectories)).sorted()

        guard !untrackedDirectories.isEmpty else {
            return
        }

        let data: [WarningState] = try untrackedDirectories.map { directory in
            let newViolations = try swiftLint.lint(
                swiftlintConfigPath: config.swiftlintConfigPath,
                directory: directory,
                projectDir: config.projectDir
            )

            return (directory: directory, new: newViolations)
        }

        try data.forEach { directory, new in
            logger.important("Dumping \(new.count) current warnings of \(directory)")
            try warningsStorage.save(jsonName: directory, warnings: new)
        }

        try git.commitFileAsIsAndPush(
            repo: config.projectDir,
            file: warningsStorage.warningsJsonsFolder.relative(to: config.projectDir),
            targetBranchName: gitlabCIEnvironmentReader.string(.CI_MERGE_REQUEST_SOURCE_BRANCH_NAME),
            remoteName: config.trackingPushRemoteName,
            commitMessage: config.trackingNewFoldersCommitMessage,
            committeeName: config.committeeName,
            committeeEmail: config.committeeEmail
        )

        reporter.newWarningLimitsHaveBeenTracked()
    }
}
