//

import Foundation
import Guardian
import SwiftlaneCore
import SwiftlaneCoreMocks
import XCTest

@testable import Swiftlane

class WarningLimitsUntrackedCheckerTests: XCTestCase {
    var checker: WarningLimitsUntrackedChecker!

    var swiftLint: SwiftLintProtocolMock!
    var filesManager: FSManagingMock!
    var warningsStorage: WarningsStoragingMock!
    var logger: LoggingMock!
    var git: GitProtocolMock!
    var reporter: WarningLimitsCheckerReportingMock!
    var slather: SlatherServicingMock!
    var gitLabCIEnvironmentReader: GitLabCIEnvironmentReadingMock!

    override func setUp() {
        super.setUp()

        swiftLint = .init()
        filesManager = .init()
        warningsStorage = .init()
        logger = .init()
        git = .init()
        reporter = .init()
        slather = .init()
        gitLabCIEnvironmentReader = .init()

        checker = WarningLimitsUntrackedChecker(
            swiftLint: swiftLint,
            filesManager: filesManager,
            warningsStorage: warningsStorage,
            logger: logger,
            git: git,
            reporter: reporter,
            slather: slather,
            gitlabCIEnvironmentReader: gitLabCIEnvironmentReader
        )

        logger.given(.logLevel(getter: .verbose))
    }

    override func tearDown() {
        super.tearDown()

        swiftLint = nil
        filesManager = nil
        warningsStorage = nil
        logger = nil
        git = nil
        reporter = nil
        slather = nil

        checker = nil
    }

    func test_doesNothingIfAllTargetsAreTracked() throws {
        // given
        let config = configStub()
        let storedWarnings = [violationStub(), violationStub()]
        let actualWarnings = storedWarnings.reversed().asArray

        prepareCommonStubs(
            config: config,
            storedWarnings: ["dir1": storedWarnings],
            actualWarnings: ["dir1": actualWarnings]
        )

        // when
        try checker.checkUntrackedLimits(config: config)

        // then
        reporter.verify(.newWarningLimitsHaveBeenTracked(), count: .never)
        git.verify(
            .commitFileAsIsAndPush(
                repo: .any,
                file: .any,
                targetBranchName: .any,
                remoteName: .any,
                commitMessage: .any,
                committeeName: .any,
                committeeEmail: .any
            ),
            count: .never
        )
    }

    func test_tracksNewTargetsWarningLimits() throws {
        // given
        let config = configStub()
        let storedWarnings = [violationStub(), violationStub()]
        let newTargetWarnings = [
            violationStub(reason: "TODO/FIXME is approaching its expiry and should be resolved soon"),
        ]
        let warningsJsonsFolder = try! config.projectDir.appending(path: "subpath/warningsJsonsFolder")

        prepareCommonStubs(
            config: config,
            storedWarnings: ["dir1": storedWarnings],
            actualWarnings: ["dir1": storedWarnings, "newTarget": newTargetWarnings]
        )

        warningsStorage.given(.warningsJsonsFolder(getter: warningsJsonsFolder))

        // when
        try checker.checkUntrackedLimits(config: config)

        // then
        reporter.verify(.newWarningLimitsHaveBeenTracked(), count: .once)

        git.verify(
            .commitFileAsIsAndPush(
                repo: .value(config.projectDir),
                file: .value(try! RelativePath("subpath/warningsJsonsFolder")),
                targetBranchName: .value("branch"),
                remoteName: .value(config.trackingPushRemoteName),
                commitMessage: .value(config.trackingNewFoldersCommitMessage),
                committeeName: .value(config.committeeName),
                committeeEmail: .value(config.committeeEmail)
            ),
            count: .once
        )
    }

    private func prepareCommonStubs(
        config: WarningLimitsCheckerConfig,
        storedWarnings: [String: [SwiftLintViolation]],
        actualWarnings: [String: [SwiftLintViolation]]
    ) {
        gitLabCIEnvironmentReader.given(
            .string(
                .value(.CI_MERGE_REQUEST_SOURCE_BRANCH_NAME),
                willReturn: "branch"
            )
        )

        slather.given(
            .readTestableTargetsNames(
                projectDir: .value(config.projectDir),
                fileName: ".testable.targets.generated.txt",
                willReturn: actualWarnings.keys.asArray
            )
        )

        warningsStorage.given(
            .readListOfDirectories(willReturn: storedWarnings.keys.asArray)
        )

        storedWarnings.forEach { directory, warnings in
            warningsStorage.given(
                .read(
                    jsonName: .value(directory),
                    willReturn: warnings
                )
            )
        }

        actualWarnings.forEach { directory, warnings in
            swiftLint.given(
                .lint(
                    swiftlintConfigPath: .value(config.swiftlintConfigPath),
                    directory: .value(directory),
                    projectDir: .value(config.projectDir),
                    willReturn: warnings
                )
            )
        }
    }

    private func configStub() -> WarningLimitsCheckerConfig {
        WarningLimitsCheckerConfig(
            projectDir: AbsolutePath.random(lastComponent: "projectDir"),
            swiftlintConfigPath: AbsolutePath.random(lastComponent: "swiftlintConfigPath"),
            trackingPushRemoteName: "test-origin-name",
            trackingNewFoldersCommitMessage: "trackingNewFoldersCommitMessage",
            loweringWarningLimitsCommitMessage: "loweringWarningLimitsCommitMessage",
            committeeName: "committeeName",
            committeeEmail: "committeeEmail"
        )
    }

    private func violationStub(
        ruleID: String? = nil,
        reason: String? = nil,
        line: Int? = nil,
        severity: SwiftLintViolation.Severity = .warning,
        file: String? = nil
    ) -> SwiftLintViolation {
        SwiftLintViolation(
            ruleID: ruleID ?? "ruleId_\(Int.random(in: 0 ... 1000))",
            reason: reason ?? "reason_\(Int.random(in: 0 ... 1000))",
            line: line ?? .random(in: 1 ... 1000),
            severity: severity,
            file: file ?? "file_\(Int.random(in: 0 ... 1000))"
        )
    }
}
