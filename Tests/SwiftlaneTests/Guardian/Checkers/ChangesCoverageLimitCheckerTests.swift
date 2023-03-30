//

import SwiftlaneCore
import SwiftlaneCoreMocks
import XCTest

@testable import Swiftlane

class ChangesCoverageLimitCheckerTests: XCTestCase {
    var checker: ChangesCoverageLimitChecker!

    var logger: LoggingMock!
    var gitlabCIEnvironmentReader: GitLabCIEnvironmentReadingMock!
    var git: GitProtocolMock!
    var slather: SlatherServicingMock!
    var reporter: ChangesCoverageReportingMock!
    var xclogparser: XCLogParserServicingMock!
    var config: ChangesCoverageLimitChecker.Config!

    override func setUp() {
        super.setUp()

        logger = .init()
        gitlabCIEnvironmentReader = .init()
        git = .init()
        slather = .init()
        reporter = .init()
        xclogparser = .init()

        logger.given(.logLevel(getter: .verbose))
    }

    private func prepareConfigAndChecker(
        excludedFileNameMatchers: [StringMatcher],
        filesToIgnoreCheck: [StringMatcher] = [try! .regex("IGNORED")],
        changedLinesCoverageLimit: Int,
        ignoredSourceBranches: [StringMatcher] = [],
        ignoredTargetBranches: [StringMatcher] = []
    ) {
        config = .init(
            decodableConfig: .init(
                filesToIgnoreCheck: filesToIgnoreCheck,
                changedLinesCoverageLimit: changedLinesCoverageLimit,
                ignoreCheckForSourceBranches: ignoredSourceBranches,
                ignoreCheckForTargetBranches: ignoredTargetBranches
            ),
            projectDir: AbsolutePath.random(lastComponent: "projectDir"),
            excludedFileNameMatchers: excludedFileNameMatchers
        )

        checker = .init(
            logger: logger,
            gitlabCIEnvironmentReader: gitlabCIEnvironmentReader,
            git: git,
            slather: slather,
            reporter: reporter,
            config: config
        )
    }

    override func tearDown() {
        super.tearDown()

        checker = nil

        logger = nil
        gitlabCIEnvironmentReader = nil
        git = nil
        slather = nil
        reporter = nil
        xclogparser = nil
        config = nil
    }

    private func prepareCommonStubs(
        sourceBranch: String,
        targetBranch: String,
        filesChangedInLastCommit: [AbsolutePath],
        changedLinesInFilesInLastCommit: [String: [Int]],
        slatherFileCodeCoverage: [SlatherFileCodeCoverage]
    ) {
        gitlabCIEnvironmentReader.given(
            .string(
                .value(.CI_MERGE_REQUEST_SOURCE_BRANCH_NAME),
                willReturn: sourceBranch
            )
        )

        gitlabCIEnvironmentReader.given(
            .string(
                .value(.CI_MERGE_REQUEST_TARGET_BRANCH_NAME),
                willReturn: targetBranch
            )
        )

        git.given(
            .filesChangedInLastCommit(
                repo: .value(config.projectDir),
                onlyExistingFiles: .value(true),
                willReturn: filesChangedInLastCommit
            )
        )

        git.given(
            .changedLinesInFilesInLastCommit(
                repo: .value(config.projectDir),
                willReturn: changedLinesInFilesInLastCommit
            )
        )

        slather.given(
            .parseCoverageJSON(
                projectDir: .value(config.projectDir),
                reportFileName: "coverage.json",
                outputDirPath: .value(try! Path("builds/results")),
                willReturn: slatherFileCodeCoverage
            )
        )
    }

    func test_correctChangesCoverage() throws {
        // given
        prepareConfigAndChecker(
            excludedFileNameMatchers: [.equals("ignored file")],
            changedLinesCoverageLimit: 100
        )

        try prepareCommonStubs(
            sourceBranch: "sourceBranch_" + .random(),
            targetBranch: "targetBranch_" + .random(),
            filesChangedInLastCommit: [
                "file_1",
                "file_2",
                "some_IGNORED_file",
                "file_3",
            ].map { try config.projectDir.appending(path: $0) },
            changedLinesInFilesInLastCommit: [
                "file_1": [1, 2, 3],
                "file_2": [4, 5, 6],
                "some_IGNORED_file": [10],
                "file_3": [1],
            ],
            slatherFileCodeCoverage: [
                SlatherFileCodeCoverage(
                    file: "file_1",
                    coverage: [1, 1, 1]
                ),
                SlatherFileCodeCoverage(
                    file: "file_2",
                    coverage: [0, 0, 0, 1, 1, 1]
                ),
                SlatherFileCodeCoverage(
                    file: "some_IGNORED_file",
                    coverage: []
                ),
                SlatherFileCodeCoverage(
                    file: "file_3",
                    coverage: [1]
                ),
            ]
        )

        // when
        try checker.checkChangedFilesCoverageLimits()

        // then
        logger.verify(.error(.any, file: .any, line: .any), count: .never)
        reporter.verify(.reportSuccess())
        reporter.verify(.reportViolation(.any, limit: .any), count: .never)
        reporter.verify(.reportCheckIsDisabledForTargetBranch(targetBranch: .any), count: .never)
    }

    func test_insufficientChangesCoverage() throws {
        // given
        prepareConfigAndChecker(
            excludedFileNameMatchers: [.equals("ignored file")],
            changedLinesCoverageLimit: 100
        )

        try prepareCommonStubs(
            sourceBranch: "sourceBranch_" + .random(),
            targetBranch: "targetBranch_" + .random(),
            filesChangedInLastCommit: [
                "file_1",
                "file_2",
                "file_3",
            ].map { try config.projectDir.appending(path: $0) },
            changedLinesInFilesInLastCommit: [
                "file_1": [1, 2, 3],
                "file_2": [1, 2, 3],
                "file_3": [1, 2],
            ],
            slatherFileCodeCoverage: [
                SlatherFileCodeCoverage(
                    file: "file_1",
                    coverage: [1, 1, 0]
                ),
                SlatherFileCodeCoverage(
                    file: "file_2",
                    coverage: [nil, nil, nil]
                ),
                SlatherFileCodeCoverage(
                    file: "file_3",
                    coverage: [0, 2]
                ),
            ]
        )

        // when
        try checker.checkChangedFilesCoverageLimits()

        // then
        logger.verify(.error(.any, file: .any, line: .any), count: .never)
        reporter.verify(.reportSuccess(), count: .never)
        reporter.verify(.reportCheckIsDisabledForTargetBranch(targetBranch: .any), count: .never)
        reporter.verify(
            .reportViolation(
                .value(.init(file: "file_1", coverageOfChangedLines: 2.0 / 3.0)),
                limit: .value(100)
            ),
            count: 1
        )
        reporter.verify(
            .reportViolation(
                .value(.init(file: "file_3", coverageOfChangedLines: 0.5)),
                limit: .value(100)
            ),
            count: 1
        )
        reporter.verify(
            .reportViolation(.matching { $0.file == "file_2" }, limit: .any),
            count: .never
        )
    }

    func test_justOnTheLimitChangesCoverage() throws {
        // given
        prepareConfigAndChecker(
            excludedFileNameMatchers: [.equals("ignored file")],
            changedLinesCoverageLimit: 50
        )

        try prepareCommonStubs(
            sourceBranch: "sourceBranch_" + .random(),
            targetBranch: "targetBranch_" + .random(),
            filesChangedInLastCommit: [
                "file_1",
            ].map { try config.projectDir.appending(path: $0) },
            changedLinesInFilesInLastCommit: [
                "file_1": [1, 2],
            ],
            slatherFileCodeCoverage: [
                SlatherFileCodeCoverage(
                    file: "file_1",
                    coverage: [1, 0]
                ),
            ]
        )

        // when
        try checker.checkChangedFilesCoverageLimits()

        // then
        logger.verify(.error(.any, file: .any, line: .any), count: .never)
        reporter.verify(.reportSuccess(), count: .once)
        reporter.verify(.reportViolation(.any, limit: .any), count: .never)
        reporter.verify(.reportCheckIsDisabledForTargetBranch(targetBranch: .any), count: .never)
    }

    func test_ignoredSourceBranch() throws {
        // given
        let sourceBranch = "sourceBranch_" + .random()
        let targetBranch = "targetBranch_" + .random()

        prepareConfigAndChecker(
            excludedFileNameMatchers: [.equals("ignored file")],
            changedLinesCoverageLimit: 50,
            ignoredSourceBranches: [.equals(sourceBranch)]
        )

        gitlabCIEnvironmentReader.given(
            .string(
                .value(.CI_MERGE_REQUEST_SOURCE_BRANCH_NAME),
                willReturn: sourceBranch
            )
        )

        gitlabCIEnvironmentReader.given(
            .string(
                .value(.CI_MERGE_REQUEST_TARGET_BRANCH_NAME),
                willReturn: targetBranch
            )
        )

        // when
        try checker.checkChangedFilesCoverageLimits()

        // then
        logger.verify(.error(.any, file: .any, line: .any), count: .never)
        reporter.verify(.reportSuccess(), count: .never)
        reporter.verify(.reportViolation(.any, limit: .any), count: .never)
        reporter.verify(.reportCheckIsDisabledForSourceBranch(sourceBranch: .value(sourceBranch)), count: .once)
        reporter.verify(.reportCheckIsDisabledForTargetBranch(targetBranch: .any), count: .never)
    }

    func test_ignoredTargetBranch() throws {
        // given
        let sourceBranch = "sourceBranch_" + .random()
        let targetBranch = "release"

        prepareConfigAndChecker(
            excludedFileNameMatchers: [.equals("ignored file")],
            changedLinesCoverageLimit: 50,
            ignoredTargetBranches: [.hasPrefix("release")]
        )

        gitlabCIEnvironmentReader.given(
            .string(
                .value(.CI_MERGE_REQUEST_SOURCE_BRANCH_NAME),
                willReturn: sourceBranch
            )
        )

        gitlabCIEnvironmentReader.given(
            .string(
                .value(.CI_MERGE_REQUEST_TARGET_BRANCH_NAME),
                willReturn: targetBranch
            )
        )

        // when
        try checker.checkChangedFilesCoverageLimits()

        // then
        logger.verify(.error(.any, file: .any, line: .any), count: .never)
        reporter.verify(.reportSuccess(), count: .never)
        reporter.verify(.reportCheckIsDisabledForTargetBranch(targetBranch: .value(targetBranch)), count: .once)
        reporter.verify(.reportViolation(.any, limit: .any), count: .never)
        reporter.verify(.reportCheckIsDisabledForSourceBranch(sourceBranch: .any), count: .never)
    }

    func test_ignoredFilesNotChecked() throws {
        // given
        prepareConfigAndChecker(
            excludedFileNameMatchers: [.contains("file_1")],
            changedLinesCoverageLimit: 50,
            ignoredTargetBranches: [.hasPrefix("release")]
        )

        try prepareCommonStubs(
            sourceBranch: "sourceBranch_" + .random(),
            targetBranch: "targetBranch_" + .random(),
            filesChangedInLastCommit: [
                "file_1",
                "file_2",
            ].map { try config.projectDir.appending(path: $0) },
            changedLinesInFilesInLastCommit: [
                "file_1": [1, 2],
                "file_2": [30, 31],
            ],
            slatherFileCodeCoverage: [
                SlatherFileCodeCoverage(
                    file: "file_1",
                    coverage: [0, 0]
                ),
                SlatherFileCodeCoverage(
                    file: "file_2",
                    coverage: [1, 1]
                ),
            ]
        )

        // when
        try checker.checkChangedFilesCoverageLimits()

        // then
        logger.verify(.error(.any, file: .any, line: .any), count: .never)
        reporter.verify(.reportSuccess(), count: .once)
        reporter.verify(.reportCheckIsDisabledForTargetBranch(targetBranch: .any), count: .never)
        reporter.verify(.reportViolation(.any, limit: .any), count: .never)
        reporter.verify(.reportCheckIsDisabledForSourceBranch(sourceBranch: .any), count: .never)
    }
}
