//

import SwiftlaneCore
import SwiftlaneCoreMocks
import SwiftlaneUnitTestTools
import XCTest

@testable import Swiftlane

class BuildErrorsCheckerTests: XCTestCase {
    var checker: BuildErrorsChecker!

    var reporter: BuildErrorsReportingMock!
    var xclogparser: XCLogParserServicingMock!
    var logger: LoggingMock!

    override func setUp() {
        super.setUp()

        xclogparser = XCLogParserServicingMock()
        reporter = BuildErrorsReportingMock()
        logger = LoggingMock()
        logger.given(.logLevel(getter: .verbose))

        checker = BuildErrorsChecker(
            xclogparser: xclogparser,
            reporter: reporter,
            logger: logger,
            config: BuildErrorsChecker.Config(
                projectDir: AbsolutePath.random(lastComponent: "projectDir"),
                derivedDataPath: AbsolutePath.random(lastComponent: "derivedDataPath"),
                htmlReportOutputDir: AbsolutePath.random(lastComponent: "htmlReportOutputDir"),
                jsonReportOutputFilePath: AbsolutePath.random(lastComponent: "jsonReportOutputFilePath")
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        checker = nil

        xclogparser = nil
        reporter = nil
    }

    func test_errorsAreReported() throws {
        // given
        let issuesReport = XCLogParserIssuesReport(
            errors: [
                .stub(),
                .stub(),
            ],
            warnings: [
                .stub(),
                .stub(),
            ]
        )

        xclogparser.given(
            .readXCLogParserReport(
                reportPath: .value(checker.config.jsonReportOutputFilePath),
                willReturn: issuesReport
            )
        )

        // when
        let result = try checker.checkBuildErrors()

        // then
        XCTAssertTrue(result)
        reporter.verify(
            .report(
                errors: .value(issuesReport.errors),
                projectDir: .value(checker.config.projectDir)
            )
        )
    }

    func test_noErrors() throws {
        // given
        let issuesReport = XCLogParserIssuesReport(
            errors: [],
            warnings: [
                .stub(),
                .stub(),
            ]
        )

        xclogparser.given(
            .readXCLogParserReport(
                reportPath: .value(checker.config.jsonReportOutputFilePath),
                willReturn: issuesReport
            )
        )

        // when
        let result = try checker.checkBuildErrors()

        // then
        XCTAssertFalse(result)
        reporter.verify(
            .report(
                errors: .any,
                projectDir: .any
            ),
            count: .never
        )
    }
}

private extension XCLogParserIssuesReport.Issue {
    static func stub() -> XCLogParserIssuesReport.Issue {
        XCLogParserIssuesReport.Issue(
            type: [.note, .error, .analyzerWarning, .failedCommandError].randomElement()!,
            title: .random(),
            clangFlag: nil,
            documentURL: .random(),
            severity: .random(in: 0 ... 1000),
            startingLineNumber: .random(in: 0 ... 1000),
            endingLineNumber: .random(in: 0 ... 1000),
            startingColumnNumber: .random(in: 0 ... 1000),
            endingColumnNumber: .random(in: 0 ... 1000),
            characterRangeEnd: .random(in: 0 ... 1000),
            characterRangeStart: .random(in: 0 ... 1000),
            interfaceBuilderIdentifier: nil,
            detail: .random()
        )
    }
}
