//

import Foundation
import Git
import Guardian
import SwiftlaneCore

// sourcery: AutoMockable
public protocol ChangesCoverageLimitChecking {
    func checkChangedFilesCoverageLimits() throws
}

public class ChangesCoverageLimitChecker {
    public struct Violation: Equatable {
        public let file: String
        public let coverageOfChangedLines: Double
    }

    private let logger: Logging
    private let gitlabCIEnvironmentReader: GitLabCIEnvironmentReading
    private let git: GitProtocol
    private let config: Config
    private let slather: SlatherServicing
    private let reporter: ChangesCoverageReporting

    public init(
        logger: Logging,
        gitlabCIEnvironmentReader: GitLabCIEnvironmentReading,
        git: GitProtocol,
        slather: SlatherServicing,
        reporter: ChangesCoverageReporting,
        config: Config
    ) {
        self.logger = logger
        self.gitlabCIEnvironmentReader = gitlabCIEnvironmentReader
        self.git = git
        self.slather = slather
        self.reporter = reporter
        self.config = config
    }

    private func findChangedButNotTestedFiles(
        minExecutableChangesFileCoverage: Double
    ) throws -> [(file: String, changesCoverage: Double)] {
        func shouldCoverFile(file: String) -> Bool {
            var shouldCover = !config.excludedFileNameMatchers.isMatching(string: file)

            if let matcher = config.decodableConfig.filesToIgnoreCheck.firstMatchingMatcher(string: file) {
                shouldCover = false
                logger.info("Ignoring coverage limit of \(file) because of ignore pattern: \"\(matcher)\"")
            }

            let fileRelativePath = file.replacingOccurrences(of: config.projectDir.string + "/", with: "")
            logger.verbose("shouldCoverFile \(fileRelativePath) will return \(shouldCover ? "✅" : "👎")")

            return shouldCover
        }

        _ = try git.filesChangedInLastCommit(repo: config.projectDir, onlyExistingFiles: true)

        logger.verbose("call Git.changedLinesInFilesInLastCommit()")
        let changedFiles = try git.changedLinesInFilesInLastCommit(repo: config.projectDir)

        logger.verbose("call generateCoverageJSONForLines()")
        let filesLinesCoverage = try slather.parseCoverageJSON(
            filePath: config.slatherReportFilePath.makeAbsoluteIfIsnt(relativeTo: config.projectDir)
        )

        var filesWithLowChangesCoverage = [(String, Double)]()

        logger.verbose("filesLinesCoverage.count = \(filesLinesCoverage.count)")
        logger.verbose("changedFiles = \(changedFiles.asPrettyJSON())")

        filesLinesCoverage
            .forEach { fileLinesCoverage in
                guard
                    let changedLinesInThisFile = changedFiles[fileLinesCoverage.file],
                    shouldCoverFile(file: fileLinesCoverage.file)
                else {
                    return
                }

                logger.verbose("changedLinesInThisFile.count = \(changedLinesInThisFile.count)")

                // Bool for each changed executable line in file representing if that line is covered.
                let coverageBools = changedLinesInThisFile.compactMap { lineNumber -> Bool? in
                    let lineCoverageIndex = lineNumber - 1

                    guard
                        lineCoverageIndex < fileLinesCoverage.coverage.count,
                        let executedTimes = fileLinesCoverage.coverage[lineCoverageIndex]
                    else {
                        return nil
                    }

                    return executedTimes > 0
                }

                logger.verbose("coverageBools.count = \(coverageBools.count)")

                let totalChangedExecutableLines = coverageBools.count
                let coveredChangedExecutableLines = coverageBools.filter { $0 }.count

                guard totalChangedExecutableLines > 0 else {
                    logger.verbose("No executable lines changed in file \(fileLinesCoverage.file)")
                    return
                }

                let changedLinesCoverage = Double(coveredChangedExecutableLines) / Double(totalChangedExecutableLines)

                logger.verbose("Executable changed lines coverage: \(changedLinesCoverage * 100)%")

                if changedLinesCoverage < minExecutableChangesFileCoverage {
                    filesWithLowChangesCoverage.append((fileLinesCoverage.file, changedLinesCoverage))
                }
            }

        logger.verbose("Undercovered changed filesManager: \(filesWithLowChangesCoverage)")

        return filesWithLowChangesCoverage
    }
}

extension ChangesCoverageLimitChecker: ChangesCoverageLimitChecking {
    public func checkChangedFilesCoverageLimits() throws {
        let sourceBranch = try gitlabCIEnvironmentReader.string(.CI_MERGE_REQUEST_SOURCE_BRANCH_NAME)
        let targetBranch = try gitlabCIEnvironmentReader.string(.CI_MERGE_REQUEST_TARGET_BRANCH_NAME)

        guard !config.decodableConfig.ignoreCheckForSourceBranches.isMatching(string: sourceBranch) else {
            reporter.reportCheckIsDisabledForSourceBranch(sourceBranch: sourceBranch)
            return
        }

        guard !config.decodableConfig.ignoreCheckForTargetBranches.isMatching(string: targetBranch) else {
            reporter.reportCheckIsDisabledForTargetBranch(targetBranch: targetBranch)
            return
        }

        let filesWithLowChangesCoverage = try findChangedButNotTestedFiles(
            minExecutableChangesFileCoverage: Double(config.decodableConfig.changedLinesCoverageLimit) / 100.0
        )

        if !filesWithLowChangesCoverage.isEmpty {
            return filesWithLowChangesCoverage
                .map {
                    .init(file: $0.file, coverageOfChangedLines: $0.changesCoverage)
                }
                .forEach {
                    reporter.reportViolation($0, limit: config.decodableConfig.changedLinesCoverageLimit)
                }
        }

        return reporter.reportSuccess()
    }
}
