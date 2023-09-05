//

import Foundation
import Guardian
import SwiftlaneCore
import SwiftlaneCoreMocks
import XCTest

@testable import Swiftlane

class WarningLimitsCheckerTests: XCTestCase {
    var checker: WarningLimitsChecker!

    var swiftLint: SwiftLintProtocolMock!
    var filesManager: FSManagingMock!
    var warningsStorage: WarningsStoragingMock!
    var logger: LoggingMock!
    var git: GitProtocolMock!
    var reporter: WarningLimitsCheckerReportingMock!
    var gitLabCIEnvironmentReader: GitLabCIEnvironmentReadingMock!

    override func setUp() {
        super.setUp()

        swiftLint = .init()
        filesManager = .init()
        warningsStorage = .init()
        logger = .init()
        git = .init()
        reporter = .init()
        gitLabCIEnvironmentReader = .init()

        checker = WarningLimitsChecker(
            swiftLint: swiftLint,
            filesManager: filesManager,
            warningsStorage: warningsStorage,
            logger: logger,
            git: git,
            reporter: reporter,
            gitlabCIEnvironmentReader: gitLabCIEnvironmentReader
        )

        logger.given(.logLevel(getter: .verbose))
    }

    override func tearDown() {
        super.tearDown()

        gitLabCIEnvironmentReader = nil
        swiftLint = nil
        filesManager = nil
        warningsStorage = nil
        logger = nil
        git = nil
        reporter = nil

        checker = nil
    }

    func test_correctWarningLimits() throws {
        // given
        let config = configStub()
        let storedWarnings = [violationStub(), violationStub()]
        let actualWarnings = storedWarnings.reversed().asArray

        prepareCommonStubs(
            config: config,
            storedWarnings: ["dir1": storedWarnings],
            actualWarnings: ["dir1": actualWarnings],
            localBranchName: "branch"
        )

        // when
        try checker.checkLimits(config: config)

        // then
        reporter.verify(.warningLimitsAreCorrect(), count: .once)

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

    func test_newNonFatalWarnings() throws {
        // given
        let config = configStub()
        let storedWarnings = [violationStub(), violationStub()]
        let actualWarnings = storedWarnings + [
            violationStub(reason: "TODO/FIXME is approaching its expiry and should be resolved soon"),
        ]

        prepareCommonStubs(
            config: config,
            storedWarnings: ["dir1": storedWarnings],
            actualWarnings: ["dir1": actualWarnings],
            localBranchName: "branch"
        )

        // when
        try checker.checkLimits(config: config)

        // then
        reporter.verify(.warningLimitsAreCorrect(), count: .once)

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

    func test_violatedWarningLimits() throws {
        // given
        let config = configStub()
        let storedWarnings1 = [violationStub(), violationStub()]
        let storedWarnings2 = [violationStub(), violationStub()]
        let newWarning1 = violationStub()
        let newWarning2 = violationStub()
        let newWarning3 = violationStub()
        let newWarning4 = violationStub(
            ruleID: newWarning3.ruleID,
            reason: newWarning3.reason,
            file: newWarning3.file
        )

        prepareCommonStubs(
            config: config,
            storedWarnings: [
                "dir1": storedWarnings1,
                "dir2": storedWarnings2,
            ],
            actualWarnings: [
                "dir1": storedWarnings1 + [newWarning1], // 1 new warning
                "dir2": storedWarnings2 + [newWarning2, newWarning3, newWarning4], // 3 new warnings
            ],
            localBranchName: "branch"
        )

        let expectedviolations = [
            WarningLimitsChecker.Violation(directory: "dir1", increase: 1),
            WarningLimitsChecker.Violation(directory: "dir2", increase: 3),
        ]
        let expectedNewWarnings = [
            [newWarning1], [newWarning2], [newWarning3, newWarning4],
        ]

        // when
        try checker.checkLimits(config: config)

        // then
        reporter.verify(
            .warningLimitsViolated(
                violations: .matching {
                    Set($0) == Set(expectedviolations)
                },
                newWarningsGroupedByMessage: .matching {
                    Set($0) == Set(expectedNewWarnings)
                }
            )
        )

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

    func test_sameWarningMovedToAnotherLine() throws {
        // given
        let config = configStub()
        let storedWarnings = [violationStub(), violationStub()]
        let actualWarnings = storedWarnings.map {
            violationStub(
                ruleID: $0.ruleID,
                reason: $0.reason,
                severity: $0.severity,
                file: $0.file
            )
        }

        prepareCommonStubs(
            config: config,
            storedWarnings: ["dir1": storedWarnings],
            actualWarnings: ["dir1": actualWarnings],
            localBranchName: "branch"
        )

        // when
        try checker.checkLimits(config: config)

        // then
        reporter.verify(.warningLimitsAreCorrect(), count: .once)

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

    func test_lowerWarningLimits() throws {
        // given
        let config = configStub()
        let storedWarnings = [violationStub(), violationStub()]
        let actualWarnings = [violationStub()]
        let warningsJsonsFolder = try config.projectDir.appending(path: "subpath/warningsJsonsFolder")
        let branch = "local-branch-name"

        prepareCommonStubs(
            config: config,
            storedWarnings: ["dir1": storedWarnings],
            actualWarnings: ["dir1": actualWarnings],
            localBranchName: branch
        )

        warningsStorage.given(.warningsJsonsFolder(getter: warningsJsonsFolder))

        // when
        try checker.checkLimits(config: config)

        // then
        reporter.verify(.warningLimitsHaveBeenLowered(), count: .once)

        warningsStorage.verify(
            .save(
                jsonName: .value("dir1"),
                warnings: .value(actualWarnings)
            ),
            count: .once
        )
        git.verify(
            .commitFileAsIsAndPush(
                repo: .value(config.projectDir),
                file: .value(try! RelativePath("subpath/warningsJsonsFolder")),
                targetBranchName: .value(branch),
                remoteName: .value(config.trackingPushRemoteName),
                commitMessage: .value(config.loweringWarningLimitsCommitMessage),
                committeeName: .value(config.committeeName),
                committeeEmail: .value(config.committeeEmail)
            ),
            count: .once
        )
    }

    private func prepareCommonStubs(
        config: WarningLimitsCheckerConfig,
        storedWarnings: [String: [SwiftLintViolation]],
        actualWarnings: [String: [SwiftLintViolation]],
        localBranchName: String
    ) {
        //		filesManager.given(
        //			.find(
        //				.value(config.warningsJsonsFolder),
        //				willReturn: Array(storedWarnings.keys)
        //			)
        //		)

        gitLabCIEnvironmentReader.given(
            .string(
                .value(.CI_MERGE_REQUEST_SOURCE_BRANCH_NAME),
                willReturn: localBranchName
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
            committeeEmail: "committeeEmail",
            testableTargetsListFile: .relative(try! RelativePath("testableTargetsListFile"))
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
