//

@testable import SwiftlaneCore
import SwiftlaneUnitTestTools
import XCTest

@testable import Swiftlane

class UnitTestsResultsCheckerTests: XCTestCase {
    var checker: UnitTestsResultsChecker!

    var junitService: JUnitServicingMock!
    var gitlabCIEnvironmentReader: GitLabCIEnvironmentReadingMock!
    var reporter: UnitTestsResultsReportingMock!
    var config: UnitTestsResultsChecker.Config!

    override func setUp() {
        super.setUp()

        junitService = .init()
        gitlabCIEnvironmentReader = .init()
        reporter = .init()

        config = UnitTestsResultsChecker.Config(
            junitPath: .random(lastComponent: "junitPath"),
            projectDir: .random(lastComponent: "projectDir")
        )

        checker = .init(
            junitService: junitService,
            gitlabCIEnvironmentReader: gitlabCIEnvironmentReader,
            reporter: reporter,
            config: config
        )
    }

    override func tearDown() {
        super.tearDown()

        checker = nil

        junitService = nil
        gitlabCIEnvironmentReader = nil
        reporter = nil
    }

    func test_failureIsReported() throws {
        // given
        let failure = JUnitTestSuites.TestSuite.TestCase.Failure(
            message: .random(),
            file: .random()
        )
        let failureTestCaseName = String.random()
        let junitReport = JUnitTestSuites(
            testsuite: [
                JUnitTestSuites.TestSuite(
                    name: .random(),
                    tests: 100,
                    failures: 1,
                    testcase: [
                        JUnitTestSuites.TestSuite.TestCase(
                            classname: .random(),
                            name: failureTestCaseName,
                            time: .random(in: 1 ... 2),
                            failure: [
                                failure,
                            ]
                        ),
                    ]
                ),
            ],
            name: .random(),
            tests: 100,
            failures: 1
        )

        junitService.given(
            .parseJUnit(
                filePath: .value(config.junitPath),
                willReturn: junitReport
            )
        )

        // when
        let result = try checker.checkIfUnitTestsFailed()

        // then
        XCTAssertTrue(result)
        reporter.verify(.failedUnitTestsDetected(.value([
            UnitTestsResultsChecker.Failure(
                failure: failure,
                testCaseName: failureTestCaseName
            ),
        ])))
        reporter.verify(
            .failedToParseJUnit(error: .any, jobUrl: .any),
            count: .never
        )
    }

    func test_noFailures() throws {
        // given
        let junitReport = JUnitTestSuites(
            testsuite: [
                JUnitTestSuites.TestSuite(
                    name: .random(),
                    tests: 100,
                    failures: 1,
                    testcase: [
                        JUnitTestSuites.TestSuite.TestCase(
                            classname: .random(),
                            name: .random(),
                            time: .random(in: 1 ... 2),
                            failure: []
                        ),
                    ]
                ),
            ],
            name: .random(),
            tests: 100,
            failures: 1
        )

        junitService.given(
            .parseJUnit(
                filePath: .value(config.junitPath),
                willReturn: junitReport
            )
        )

        // when
        let result = try checker.checkIfUnitTestsFailed()

        // then
        XCTAssertFalse(result)
        reporter.verify(
            .failedUnitTestsDetected(.any),
            count: .never
        )
        reporter.verify(
            .failedToParseJUnit(error: .any, jobUrl: .any),
            count: .never
        )
    }

    func test_parsingErrorIsReported() throws {
        // given
        enum StubError: Error {
            case error
        }

        let jobURL = String.random()

        gitlabCIEnvironmentReader.given(
            .string(
                .value(.CI_JOB_URL),
                willReturn: jobURL
            )
        )
        junitService.given(
            .parseJUnit(
                filePath: .value(config.junitPath),
                willThrow: StubError.error
            )
        )

        // when
        let result = try checker.checkIfUnitTestsFailed()

        // then
        XCTAssertTrue(result)
        reporter.verify(
            .failedUnitTestsDetected(.any),
            count: .never
        )
        reporter.verify(
            .failedToParseJUnit(error: .any, jobUrl: .value(jobURL)),
            count: .once
        )
    }
}
