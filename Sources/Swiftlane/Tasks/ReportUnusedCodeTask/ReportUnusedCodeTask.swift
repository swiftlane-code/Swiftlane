//

import Foundation

import AppStoreConnectAPI
import Combine
import Guardian
import MattermostAPI
import Networking
import Provisioning
import Simulator
import SwiftlaneCore
import Xcodebuild

public struct ReportUnusedCodeTaskConfig {
    public let projectDir: AbsolutePath
    public let reportedFiles: [RelativePath]
    public let ignoredTypesNames: [String]
    public let mattermostWebhookKey: String?
    public let buildUsingPeriphery: Bool
}

public final class ReportUnusedCodeTask {
    public enum Errors: Error, CustomStringConvertible {
        case releaseConfigurationIsNotSupported

        public var description: String {
            switch self {
            case .releaseConfigurationIsNotSupported:
                return "Release configuration is not supported because Xcode doesn't generate IndexStore when building Release configuration."
            }
        }
    }

    private let logger: Logging
    private let shell: ShellExecuting
    private let filesManager: FSManaging
    private let peripheryService: PeripheryServicing
    private let resultsFormatter: PeripheryResultsFormatting
    private let paths: PathsFactoring
    private let gitlabCIEnvironment: GitLabCIEnvironmentReading
    private let mattermostAPIClient: MattermostAPIClient?

    private let config: ReportUnusedCodeTaskConfig

    public init(
        logger: Logging,
        shell: ShellExecuting,
        filesManager: FSManaging,
        peripheryService: PeripheryServicing,
        resultsFormatter: PeripheryResultsFormatting,
        paths: PathsFactoring,
        gitlabCIEnvironment: GitLabCIEnvironmentReading,
        mattermostAPIClient: MattermostAPIClient?,
        config: ReportUnusedCodeTaskConfig
    ) {
        self.logger = logger
        self.shell = shell
        self.filesManager = filesManager
        self.peripheryService = peripheryService
        self.resultsFormatter = resultsFormatter
        self.paths = paths
        self.gitlabCIEnvironment = gitlabCIEnvironment
        self.mattermostAPIClient = mattermostAPIClient
        self.config = config
    }

    private func makeReportMarkdown(in file: RelativePath, results: [PeripheryModels.ScanResult]) throws -> String {
        let toBeReported = try results.filter {
            let relativeLocation = try $0.location.file.relative(to: config.projectDir)
            return relativeLocation == file
        }

        let warnings = try resultsFormatter.format(results: toBeReported)

        let reportTitle = "### \(toBeReported.count) warnings in _\(file)_\n\n"
        let report = reportTitle + warnings
        return report
    }

    private func makeReportForMattermost(in file: RelativePath, results: [PeripheryModels.ScanResult]) throws -> String {
        let toBeReported = try results.filter {
            let relativeLocation = try $0.location.file.relative(to: config.projectDir)
            return relativeLocation == file
        }

        let warnings = try resultsFormatter.format(results: toBeReported)

        let reportTitle = "##### \(toBeReported.count) warnings in _\(file)_\n\n"
        let report = reportTitle + warnings
        return report
    }

    private func runPeriphery(derivedDataPath: AbsolutePath) throws -> [PeripheryModels.ScanResult] {
        do {
            let results = try peripheryService.scan(
                projectDir: config.projectDir,
                derivedDataPath: derivedDataPath,
                build: config.buildUsingPeriphery
            ).filter {
                !config.ignoredTypesNames.contains($0.name)
            }
            return results
        } catch {
            logger.error("Make sure to build before scanning for unused code OR pass `--build` flag to enable build using periphery.")
            throw error
        }
    }

    private func scanUnusedCode(derivedDataPath: AbsolutePath) throws {
        logger.important("Running periphery...")

        let results = try runPeriphery(derivedDataPath: derivedDataPath)

        logger.important("Total issues found by periphery: \(results.count)")

        var usedReportNames = Set<String>()

        func makeUniqueReportName(file: RelativePath) -> String {
            var reportName = "unused_code_report/\(file.lastComponent).md"
            var reportNameIndex = 1
            while usedReportNames.contains(reportName) {
                reportName = "unused_code_report/\(file.lastComponent)_\(reportNameIndex).md"
                reportNameIndex += 1
            }
            usedReportNames.insert(reportName)
            return reportName
        }

        try config.reportedFiles.enumerated().forEach { _, file in
            logger.important("Creating unused code report for file \(file.string.quoted)...")

            let markdownReport = try makeReportMarkdown(in: file, results: results)

            let reportName = makeUniqueReportName(file: file)
            let reportPath = try paths.resultsDir.appending(path: reportName)
            try filesManager.write(reportPath, text: markdownReport)

            let mattermostReport = try makeReportForMattermost(in: file, results: results)
            try postReportToMattermost(text: mattermostReport)
        }
    }

    private func postReportToMattermost(text: String) throws {
        guard let api = mattermostAPIClient, let hookKey = config.mattermostWebhookKey else {
            logger.warn("Mattermost webhook was not passed to the command.")
            return
        }
        let jobURL = try gitlabCIEnvironment.string(.CI_JOB_URL)
        let title = "[CI JOB](\(jobURL))\n"
        try api.postWebhook(hookKey: hookKey, body: ["text": title + text]).await()
    }

    public func run() throws {
        logger.important("Going to start scanning for unused code.")
        try scanUnusedCode(derivedDataPath: paths.derivedDataDir)
    }
}
