//

import Foundation
import Guardian
import SwiftlaneCore
import Xcodebuild

// sourcery: AutoMockable
public protocol UnitTestsExitCodeChecking {
    func checkUnitTestsExitCode() throws -> Bool
}

public class UnitTestsExitCodeChecker {
    public struct CheckerData {
        public let unitTestsExitCode: Int

        public init(unitTestsExitCode: Int) {
            self.unitTestsExitCode = unitTestsExitCode
        }
    }

    private let checkerData: CheckerData
    private let environmentValueReader: EnvironmentValueReading
    private let gitlabCIEnvironmentReader: GitLabCIEnvironmentReading
    private let reporter: MergeRequestReporting
    private let filesManager: FSManaging
    private let config: Config

    public init(
        checkerData: CheckerData,
        environmentValueReader: EnvironmentValueReading,
        gitlabCIEnvironmentReader: GitLabCIEnvironmentReading,
        reporter: MergeRequestReporting,
        filesManager: FSManaging,
        config: Config
    ) {
        self.checkerData = checkerData
        self.environmentValueReader = environmentValueReader
        self.gitlabCIEnvironmentReader = gitlabCIEnvironmentReader
        self.reporter = reporter
        self.filesManager = filesManager
        self.config = config
    }
}

extension UnitTestsExitCodeChecker: UnitTestsExitCodeChecking {
    public func checkUnitTestsExitCode() throws -> Bool {
        guard checkerData.unitTestsExitCode != 0 else { return false }

        let jobURL = try gitlabCIEnvironmentReader.string(.CI_JOB_URL)

        if let failureReason = XcodebuildError.Reason(rawValue: checkerData.unitTestsExitCode) {
            reporter.fail(failureReason.description)
        } else {
            reporter.fail("test run finished with a non-zero exit code (\(checkerData.unitTestsExitCode)), check job logs. \(jobURL)")
        }

        try filesManager.find(config.logsDir)
            .filter { $0.lastComponent.hasPrefix(LogPathFactory.stderrLogFileNamePrefix) }
            .forEach { logfile in
                let text = try filesManager.readText(logfile, log: true)
                    .suffix(1000)
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard !text.isEmpty else { return }

                let relativePath = (try? logfile.relative(to: config.projectDir).string) ?? logfile.string
                reporter.fail(relativePath + "\n\n```\n\(text)\n```")
            }
        return true
    }
}
