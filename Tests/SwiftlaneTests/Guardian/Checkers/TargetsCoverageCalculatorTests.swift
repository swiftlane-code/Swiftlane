//

import Foundation
import SwiftlaneCore
import SwiftlaneCoreMocks
import SwiftlaneUnitTestTools
import XCTest

@testable import Swiftlane

class TargetsCoverageCalculatorTests: XCTestCase {
    var logger: LoggingMock!
    var projectDir: AbsolutePath!

    override func setUp() {
        super.setUp()

        logger = LoggingMock()
        logger.given(.logLevel(getter: .verbose))

        projectDir = AbsolutePath.random(lastComponent: "prj")
    }

    func test_coverageOfOneTargetIsSummedFromFiles() throws {
        // given
        let config = TargetCoverageCalculator.Config(
            defaultFilters: [.equals("default")],
            excludeFilesFilters: [:],
            targetCoverageLimits: ["TARGET_1": .init(limit: 30, filtersSetsNames: nil)],
            projectDir: projectDir
        )
        let calculator = TargetCoverageCalculator(logger: logger, config: config)
        let allTargetsCoverage: [XCCOVTargetCoverage] = [
            .init(
                name: "TARGET_1",
                executableLines: -1,
                coveredLines: -1,
                lineCoverage: -1,
                files: [
                    .init(
                        name: .random(),
                        path: .random(),
                        executableLines: 1000,
                        coveredLines: 10,
                        lineCoverage: -1
                    ),
                    .init(
                        name: .random(),
                        path: .random(),
                        executableLines: 9000,
                        coveredLines: 40,
                        lineCoverage: -1
                    ),
                ]
            ),
        ]

        // when
        let calculated = try calculator.calculateTargetsCoverage(targets: allTargetsCoverage)

        // then
        XCTAssertEqual(calculated, [.init(
            targetName: "TARGET_1",
            executableLines: 10000,
            coveredLines: 50,
            lineCoverage: 0.005,
            limitInt: 30
        )])
    }

    func test_coverageOfExcludedFilesIsNotCalculated() throws {
        // given
        let config = TargetCoverageCalculator.Config(
            defaultFilters: [
                .hasSuffix("ignored"),
                .equals("ignored_2"),
            ],
            excludeFilesFilters: [:],
            targetCoverageLimits: ["TARGET_1": .init(limit: 30, filtersSetsNames: nil)],
            projectDir: projectDir
        )
        let calculator = TargetCoverageCalculator(logger: logger, config: config)
        let allTargetsCoverage: [XCCOVTargetCoverage] = [
            .init(
                name: "TARGET_1",
                executableLines: -1,
                coveredLines: -1,
                lineCoverage: -1,
                files: [
                    .init(
                        name: .random(),
                        path: .random(),
                        executableLines: 1000,
                        coveredLines: 10,
                        lineCoverage: -1
                    ),
                    .init(
                        name: .random(),
                        path: try projectDir.appending(path: "ignored").string,
                        executableLines: 9000,
                        coveredLines: 40,
                        lineCoverage: -1
                    ),
                    .init(
                        name: .random(),
                        path: try projectDir.appending(path: "ignored_2").string,
                        executableLines: 9000,
                        coveredLines: 40,
                        lineCoverage: -1
                    ),
                ]
            ),
        ]

        // when
        let calculated = try calculator.calculateTargetsCoverage(targets: allTargetsCoverage)

        // then
        XCTAssertEqual(calculated, [.init(
            targetName: "TARGET_1",
            executableLines: 1000,
            coveredLines: 10,
            lineCoverage: 0.01,
            limitInt: 30
        )])
    }
}
