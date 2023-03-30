//

import Foundation
import SwiftlaneCore
import XCTest

@testable import Xcodebuild

class XCTestPlanServiceTests: XCTestCase {
    var service: XCTestPlanService!

    var testPlanFinder: XCTestPlanFindingMock!
    var testPlanParser: XCTestPlanParsingMock!

    override func setUp() {
        super.setUp()

        testPlanFinder = XCTestPlanFindingMock()
        testPlanParser = XCTestPlanParsingMock()

        service = XCTestPlanService(
            testPlanFinder: testPlanFinder,
            testPlanParser: testPlanParser
        )
    }

    override func tearDown() {
        service = nil

        testPlanFinder = nil
        testPlanParser = nil

        super.tearDown()
    }

    func testGetTestPlanNamed_returnsCorrectTestPlan() throws {
        // given
        let derivedDataPath = AbsolutePath.random()
        let testPlanNames = [UUID().uuidString, UUID().uuidString]
        let testPlanPaths = try testPlanNames.map { $0 + ".xctestplan" }.map { try AbsolutePath.random().appending(path: $0) }
        let testPlanStubs: [XCTestPlanInfo] = testPlanNames.map { .stub(name: $0) }

        testPlanFinder.given(
            .findXCTestPlans(
                derivedDataPath: .value(derivedDataPath),
                willReturn: testPlanPaths
            )
        )

        testPlanParser.given(
            .parseTestPlan(
                path: .value(testPlanPaths[0]),
                willReturn: testPlanStubs[0]
            )
        )

        testPlanParser.given(
            .parseTestPlan(
                path: .value(testPlanPaths[1]),
                willReturn: testPlanStubs[1]
            )
        )

        // when
        let result = try service.getTestPlan(named: testPlanNames[1], inDerivedDataPath: derivedDataPath)

        // then
        XCTAssertEqual(result, testPlanStubs[1])
    }

    func testGetTestPlan_wrongName_throwsError() throws {
        // given
        let derivedDataPath = AbsolutePath.random()

        testPlanFinder.given(
            .findXCTestPlans(
                derivedDataPath: .value(derivedDataPath),
                willReturn: [AbsolutePath.random()]
            )
        )

        testPlanParser.given(
            .parseTestPlan(
                path: .any,
                willReturn: .stub()
            )
        )

        let findName = UUID().uuidString

        // when & then
        XCTAssertThrowsError(
            try service.getTestPlan(named: findName, inDerivedDataPath: derivedDataPath)
        ) { error in
            XCTAssertEqual(
                error as? XCTestPlanService.Errors,
                XCTestPlanService.Errors.testPlanNotFound(
                    testPlanName: findName,
                    derivedDataPath: derivedDataPath.string
                )
            )
        }
    }
}

private extension XCTestPlanInfo {
    static func stub(name: String? = nil) -> XCTestPlanInfo {
        XCTestPlanInfo(
            name: name ?? UUID().uuidString,
            selectedTests: [
                UUID().uuidString,
            ],
            skippedTests: [
                UUID().uuidString,
                UUID().uuidString,
                UUID().uuidString,
            ]
        )
    }
}
