//

import SwiftlaneCore
import SwiftlaneCoreMocks
import SwiftlaneUnitTestTools
import XCTest

@testable import Swiftlane

class TargetsCoverageLimitCheckerTests: XCTestCase {
    var checker: TargetsCoverageLimitChecker!

    var filesManager: FSManagingMock!
    var shell: ShellExecutingMock!
    var xccov: XCCOVServicingMock!
    var targetsFilterer: TargetsCoverageTargetsFilteringMock!
    var coverageCalculator: TargetCoverageCalculatingMock!
    var reporter: TargetCoverageReportingMock!
    var config: TargetsCoverageLimitChecker.Config!

    override func setUp() {
        super.setUp()

        filesManager = .init()
        shell = .init()
        xccov = .init()
        targetsFilterer = .init()
        coverageCalculator = .init()
        reporter = .init()
        config = .init(
            decodableConfig: TargetsCoverageLimitChecker.DecodableConfig(
                excludeFilesFilters: ["base": []],
                targetCoverageLimits: [:],
                allowedProductNameSuffixes: [".app", ".framework"],
                excludeTargetsNames: [.equals("EXCLUDE_1"), .equals("EXCLUDE_2")], 
                totalCodeCoverageMessagePrefix: nil
            ),
            projectDir: AbsolutePath.random(lastComponent: "projectDir"),
            xcresultDir: AbsolutePath.random(lastComponent: "xcresultDir"),
            xccovTempCoverageFilePath: AbsolutePath.random(lastComponent: "xccovTempCoverageFilePath")
        )

        let logger = LoggingMock()
        logger.given(.logLevel(getter: .verbose))

        checker = TargetsCoverageLimitChecker(
            logger: logger,
            filesManager: filesManager,
            shell: shell,
            xccov: xccov,
            targetsFilterer: targetsFilterer,
            coverageCalculator: coverageCalculator,
            reporter: reporter,
            config: config
        )
    }

    override func tearDown() {
        super.tearDown()

        checker = nil

        filesManager = nil
        shell = nil
        xccov = nil
        coverageCalculator = nil
        targetsFilterer = nil
        reporter = nil
        config = nil
    }

    func test_invalidCoverageOfOneTarget() throws {
        // given
        let xcresultPath = AbsolutePath.random(lastComponent: "some.xcresult")
        let allTargetsCoverage: [XCCOVTargetCoverage] = [
            .init(
                name: .random(),
                executableLines: .random(in: 0 ... 1000),
                coveredLines: .random(in: 0 ... 1000),
                lineCoverage: .random(in: 0 ... 1),
                files: []
            ),
            .init(
                name: .random(),
                executableLines: .random(in: 0 ... 1000),
                coveredLines: .random(in: 0 ... 1000),
                lineCoverage: .random(in: 0 ... 1),
                files: []
            ),
        ]
        let filteredTargetsCoverage: [XCCOVTargetCoverage] = [
            .init(
                name: "TARGET_1",
                executableLines: .random(in: 0 ... 1000),
                coveredLines: .random(in: 0 ... 1000),
                lineCoverage: 0.1,
                files: []
            ),
            .init(
                name: "TARGET_2",
                executableLines: .random(in: 0 ... 1000),
                coveredLines: .random(in: 0 ... 1000),
                lineCoverage: 0.2,
                files: []
            ),
        ]
        let processedCoverage: [CalculatedTargetCoverage] = [
            .init(
                targetName: "TARGET_1",
                executableLines: .random(in: 0 ... 1000),
                coveredLines: .random(in: 0 ... 1000),
                lineCoverage: 0.1,
                limitInt: 10
            ),
            .init(
                targetName: "TARGET_2",
                executableLines: .random(in: 0 ... 1000),
                coveredLines: .random(in: 0 ... 1000),
                lineCoverage: 0.2,
                limitInt: 39
            ),
        ]
        let xccovReport = XCCOVCoverageReport(
            lineCoverage: .random(in: 0 ... 1),
            targets: allTargetsCoverage
        )

        filesManager.given(
            .find(
                .value(config.xcresultDir),
                file: .any,
                line: .any,
                willReturn: [.random(), xcresultPath, .random()]
            )
        )

        coverageCalculator.given(
            .calculateTargetsCoverage(targets: .value(filteredTargetsCoverage), willReturn: processedCoverage)
        )

        xccov.given(.generateAndParseCoverageReport(
            xcresultPath: .value(xcresultPath),
            generatedCoverageFilePath: .value(config.xccovTempCoverageFilePath),
            willReturn: xccovReport
        ))

        targetsFilterer.given(
            .filterTargets(
                report: .any,
                allowedProductNameSuffixes: .value(config.decodableConfig.allowedProductNameSuffixes),
                excludeTargetsNames: .value(config.decodableConfig.excludeTargetsNames),
                willReturn: filteredTargetsCoverage
            )
        )

        // when
        try checker.checkTargetsCodeCoverage()

        // then
        reporter.verify(
            .reportAllTargetsCoverage(
                targets: .value(processedCoverage)
            )
        )
        reporter.verify(.reportCoverageLimitsSuccess(), count: .never)
        reporter.verify(
            .reportCoverageLimitsCheckFailed(
                violation: .value(
                    TargetsCoverageLimitChecker.Violation(
                        targetName: "TARGET_2",
                        minCoverage: Double(processedCoverage[1].limitInt!) / 100,
                        actualCoverage: 0.2
                    )
                )
            )
        )
    }

    func test_goodCoverageOfBothTargets() throws {
        // given
        let xcresultPath = AbsolutePath.random(lastComponent: "some.xcresult")
        let allTargetsCoverage: [XCCOVTargetCoverage] = [
            .init(
                name: .random(),
                executableLines: .random(in: 0 ... 1000),
                coveredLines: .random(in: 0 ... 1000),
                lineCoverage: .random(in: 0 ... 1),
                files: []
            ),
            .init(
                name: .random(),
                executableLines: .random(in: 0 ... 1000),
                coveredLines: .random(in: 0 ... 1000),
                lineCoverage: .random(in: 0 ... 1),
                files: []
            ),
        ]
        let filteredTargetsCoverage: [XCCOVTargetCoverage] = [
            .init(
                name: "TARGET_1",
                executableLines: .random(in: 0 ... 1000),
                coveredLines: .random(in: 0 ... 1000),
                lineCoverage: 0.1,
                files: []
            ),
            .init(
                name: "TARGET_2",
                executableLines: .random(in: 0 ... 1000),
                coveredLines: .random(in: 0 ... 1000),
                lineCoverage: 0.3,
                files: []
            ),
        ]
        let processedCoverage: [CalculatedTargetCoverage] = [
            .init(
                targetName: "TARGET_1",
                executableLines: .random(in: 0 ... 1000),
                coveredLines: .random(in: 0 ... 1000),
                lineCoverage: 0.1,
                limitInt: 10
            ),
            .init(
                targetName: "TARGET_2",
                executableLines: .random(in: 0 ... 1000),
                coveredLines: .random(in: 0 ... 1000),
                lineCoverage: 0.3,
                limitInt: 30
            ),
        ]
        let xccovReport = XCCOVCoverageReport(
            lineCoverage: .random(in: 0 ... 1),
            targets: allTargetsCoverage
        )

        filesManager.given(
            .find(
                .value(config.xcresultDir),
                file: .any,
                line: .any,
                willReturn: [.random(), xcresultPath, .random()]
            )
        )

        coverageCalculator.given(
            .calculateTargetsCoverage(targets: .value(filteredTargetsCoverage), willReturn: processedCoverage)
        )

        xccov.given(
            .generateAndParseCoverageReport(
                xcresultPath: .value(xcresultPath),
                generatedCoverageFilePath: .value(config.xccovTempCoverageFilePath),
                willReturn: xccovReport
            )
        )

        targetsFilterer.given(
            .filterTargets(
                report: .any,
                allowedProductNameSuffixes: .value(config.decodableConfig.allowedProductNameSuffixes),
                excludeTargetsNames: .value(config.decodableConfig.excludeTargetsNames),
                willReturn: filteredTargetsCoverage
            )
        )

        // when
        try checker.checkTargetsCodeCoverage()

        // then
        reporter.verify(
            .reportAllTargetsCoverage(
                targets: .value(processedCoverage)
            )
        )
        reporter.verify(.reportCoverageLimitsSuccess())
        reporter.verify(
            .reportCoverageLimitsCheckFailed(
                violation: .any
            ), count: .never
        )
    }
}
