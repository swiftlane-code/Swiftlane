//

import Foundation
import Git
import Guardian
import SwiftlaneCore

private typealias WarningState = (
    directory: String,
    old: [SwiftLintViolation],
    new: [SwiftLintViolation]
)

// sourcery: AutoMockable
public protocol WarningLimitsChecking {
    func checkLimits(config: WarningLimitsCheckerConfig) throws
}

public class WarningLimitsChecker {
    public struct Violation: Equatable, Hashable {
        public let directory: String
        public let increase: Int
    }

    private let swiftLint: SwiftLintProtocol
    private let filesManager: FSManaging
    private let warningsStorage: WarningsStoraging
    private let logger: Logging
    private let git: GitProtocol
    private let reporter: WarningLimitsCheckerReporting
    private let gitlabCIEnvironmentReader: GitLabCIEnvironmentReading

    public init(
        swiftLint: SwiftLintProtocol,
        filesManager: FSManaging,
        warningsStorage: WarningsStoraging,
        logger: Logging,
        git: GitProtocol,
        reporter: WarningLimitsCheckerReporting,
        gitlabCIEnvironmentReader: GitLabCIEnvironmentReading
    ) {
        self.swiftLint = swiftLint
        self.filesManager = filesManager
        self.warningsStorage = warningsStorage
        self.logger = logger
        self.git = git
        self.reporter = reporter
        self.gitlabCIEnvironmentReader = gitlabCIEnvironmentReader
    }

    /// Ignores same warning only moved to another line.
    ///
    /// Result contains only warnings which count was increased.
    ///
    /// Groups warnings together if (same message) and (same file).
    ///
    /// Returns: array of *Array of same warnings in single file*.
    private func extractNewWarnings(_ state: WarningState) -> [[SwiftLintViolation]] {
        /// Key used to count same warning in a specific file ignoring its line number.
        struct Key: Hashable, Equatable {
            let file: String
            let message: String

            public init(from violation: SwiftLintViolation) {
                /// Messages of those warnings contain specific numbers which
                /// leads to "Amount of this warning has increased" message in danger report.
                let ruleIdsToIgnoreMessage = [
                    "line_length", "file_length", "type_body_length",
                ]

                file = violation.file
                message = ruleIdsToIgnoreMessage.contains(violation.ruleID)
                    ? violation.ruleID : violation.messageText
            }
        }

        let oldCount = state.old.reduce(into: [Key: Int]()) { result, warning in
            result[Key(from: warning), default: 0] += 1
        }
        let newCount = state.new.reduce(into: [Key: Int]()) { result, warning in
            result[Key(from: warning), default: 0] += 1
        }
        let countChanges = newCount.map { key, newCount in
            (key: key, change: newCount - (oldCount[key] ?? 0))
        }
        let increasedCounts = countChanges.filter {
            $0.change > 0
        }
        let increasedCountsWarnings = increasedCounts.map { key, _ in
            state.new.filter { Key(from: $0) == key } // never empty
        }
        return increasedCountsWarnings
    }

    private func checkIfWarningLimitsViolated(data: [WarningState]) throws -> Bool {
        let criticalData = filterCriticalWarnings(data: data)

        let criticalWarningsIncreased = criticalData
            .filter { _, old, new in
                new.count > old.count
            }

        guard criticalWarningsIncreased.isEmpty else {
            let allWarningsIncreased = data
                .filter { _, old, new in
                    new.count > old.count
                }

            logAllNewWarnings(increased: allWarningsIncreased)

            // array of (array of same warnings in a file)
            let newWarningsGroupedByMessage = data.flatMap { directoryState in
                extractNewWarnings(directoryState)
            }

            let violations = criticalWarningsIncreased.map {
                Violation(
                    directory: $0.directory,
                    increase: $0.new.count - $0.old.count
                )
            }

            reporter.warningLimitsViolated(
                violations: violations,
                newWarningsGroupedByMessage: newWarningsGroupedByMessage
            )

            return true
        }

        return false
    }

    /// Returs: `true` if warning limits have been lowered, otherwise `false`.
    private func lowerWarningLimits(config: WarningLimitsCheckerConfig, data: [WarningState]) throws -> Bool {
        let criticalData = filterCriticalWarnings(data: data)

        let lowered = criticalData.filter { _, old, new in
            new.count < old.count
        }
        try lowered.forEach { directory, old, new in
            logger.important("Lowering limit of \(directory) from \(old.count) to \(new.count)")
            try warningsStorage.save(jsonName: directory, warnings: new)
        }
        guard !lowered.isEmpty else {
            return false
        }

        try git.commitFileAsIsAndPush(
            repo: config.projectDir,
            file: warningsStorage.warningsJsonsFolder.relative(to: config.projectDir),
            targetBranchName: gitlabCIEnvironmentReader.string(.CI_MERGE_REQUEST_SOURCE_BRANCH_NAME),
            remoteName: config.trackingPushRemoteName,
            commitMessage: config.loweringWarningLimitsCommitMessage,
            committeeName: config.committeeName,
            committeeEmail: config.committeeEmail
        )

        reporter.warningLimitsHaveBeenLowered()
        return true
    }

    private func filterCriticalWarnings(data: [WarningState]) -> [WarningState] {
        func shouldFailBuild(_ violation: SwiftLintViolation) -> Bool {
            !violation.messageText
                .contains("TODO/FIXME is approaching its expiry and should be resolved soon")
        }

        return data
            .map { directory, old, new -> WarningState in
                (
                    directory: directory,
                    old: old.filter(shouldFailBuild),
                    new: new.filter(shouldFailBuild)
                )
            }
    }

    /// Logs all warnings not present in stored jsons.
    /// Includes warnings which were only moved to another line (those are not really new ones).
    private func logAllNewWarnings(increased: [WarningState]) {
        let rows = increased
            .flatMap { _, old, new -> [SwiftLintViolation] in
                let oldSet = Set(old)
                return new.filter { !oldSet.contains($0) }
            }
            .map { warning in
                "\t\(warning.file):\(warning.line) > \(warning.messageText)"
            }
            .joined(separator: "\n")

        if !rows.isEmpty {
            logger.debug("New warnings: \n" + rows)
        }
    }
}

extension WarningLimitsChecker: WarningLimitsChecking {
    public func checkLimits(config: WarningLimitsCheckerConfig) throws {
        let directories = try warningsStorage.readListOfDirectories()

        let data: [WarningState] = try directories.map { directory in
            let oldViolations = try warningsStorage.read(
                jsonName: directory
            )

            let newViolations = try swiftLint.lint(
                swiftlintConfigPath: config.swiftlintConfigPath,
                directory: directory,
                projectDir: config.projectDir
            )

            return (directory: directory, old: oldViolations, new: newViolations)
        }

        if
            try !checkIfWarningLimitsViolated(data: data),
            try !lowerWarningLimits(config: config, data: data)
        {
            reporter.warningLimitsAreCorrect()
        }
    }
}
