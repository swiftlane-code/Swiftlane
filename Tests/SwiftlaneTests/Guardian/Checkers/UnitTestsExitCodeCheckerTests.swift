//

import SwiftlaneCore
import SwiftlaneCoreMocks
import XCTest

@testable import Swiftlane

class UnitTestsExitCodeCheckerTests: XCTestCase {
    var checker: UnitTestsExitCodeChecker!

    var environmentValueReader: EnvironmentValueReadingMock!
    var gitlabCIEnvironmentReader: GitLabCIEnvironmentReadingMock!
    var filesManager: FSManagingMock!
    var reporter: MergeRequestReportingMock!
    var config: UnitTestsExitCodeChecker.Config!

    override func setUp() {
        super.setUp()

        environmentValueReader = EnvironmentValueReadingMock()
        gitlabCIEnvironmentReader = GitLabCIEnvironmentReadingMock()
        filesManager = FSManagingMock()
        reporter = MergeRequestReportingMock()

        config = UnitTestsExitCodeChecker.Config(
            projectDir: .random(lastComponent: "projectDir"),
            logsDir: .random(lastComponent: "logsDir")
        )

        checker = UnitTestsExitCodeChecker(
            checkerData: UnitTestsExitCodeChecker.CheckerData(unitTestsExitCode: 0),
            environmentValueReader: environmentValueReader,
            gitlabCIEnvironmentReader: gitlabCIEnvironmentReader,
            reporter: reporter,
            filesManager: filesManager,
            config: config
        )
    }

    override func tearDown() {
        super.tearDown()

        config = nil
        checker = nil

        environmentValueReader = nil
        gitlabCIEnvironmentReader = nil
        filesManager = nil
        reporter = nil
    }

    func test_failFromFastlaneExitCode() throws {
        // given
        let jobURL = "jobUrl_" + UUID().uuidString
        let exitCode = 1
        let stdErrLogFile = AbsolutePath.random(lastComponent: "stderr_somelog.log")

        checker = UnitTestsExitCodeChecker(
            checkerData: UnitTestsExitCodeChecker.CheckerData(unitTestsExitCode: exitCode),
            environmentValueReader: environmentValueReader,
            gitlabCIEnvironmentReader: gitlabCIEnvironmentReader,
            reporter: reporter,
            filesManager: filesManager,
            config: UnitTestsExitCodeChecker.Config(
                projectDir: .random(lastComponent: "projectDir"),
                logsDir: .random(lastComponent: "logsDir")
            )
        )

        gitlabCIEnvironmentReader.given(.string(.value(.CI_JOB_URL), willReturn: jobURL))
        filesManager.given(
            .find(
                .value(config.logsDir),
                file: .any,
                line: .any,
                willReturn: [stdErrLogFile]
            )
        )
        filesManager.given(
            .readText(.value(stdErrLogFile), log: .any, willReturn: "wow such much errors in this log")
        )

        // when
        let result = try checker.checkUnitTestsExitCode()

        // then
        XCTAssertEqual(result, true)

        reporter.verify(.fail(.value("test run finished with a non-zero exit code (\(exitCode)), check job logs. \(jobURL)")))
        reporter.verify(.fail(.matching { $0.contains("wow such much errors in this log") }))
        reporter.verify(.createOrUpdateReport(), count: .never)
    }

    func test_success() throws {
        // given

        // when
        let result = try checker.checkUnitTestsExitCode()

        // then
        XCTAssertEqual(result, false)

        reporter.verify(.fail(.any), count: .never)
        reporter.verify(.createOrUpdateReport(), count: .never)
    }
}
