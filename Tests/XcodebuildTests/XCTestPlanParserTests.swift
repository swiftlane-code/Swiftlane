//

import Foundation
import SwiftlaneCore
import SwiftlaneCoreMocks
import XCTest

@testable import Xcodebuild

class XCTestPlanParserTests: XCTestCase {
    var parser: XCTestPlanParser!

    var filesManager: FSManagingMock!

    override func setUp() {
        super.setUp()

        filesManager = FSManagingMock()

        parser = XCTestPlanParser(filesManager: filesManager)
    }

    override func tearDown() {
        filesManager = nil

        super.tearDown()
    }

    func test_parseWrongFileExtension_throwsError() throws {
        // given
        let path = AbsolutePath.random(suffix: ".wrongExt")

        // when & then
        XCTAssertThrowsError(
            try parser.parseTestPlan(path: path)
        ) { error in
            XCTAssertEqual(
                error as? XCTestPlanParser.Errors,
                .notXCTestPlanFile(path.string)
            )
        }
    }

    func test_onlySkippedTests_parsedCorrectly() throws {
        // given
        let name = UUID().uuidString
        let path = AbsolutePath.random(lastComponent: name + ".xctestplan")
        let data = try Bundle.module.readStubData(path: "TestPlanWithSkippedTests.json")

        filesManager.given(.readData(.value(path), log: .any, willReturn: data))

        // when
        let result = try parser.parseTestPlan(path: path)

        // then
        XCTAssertEqual(
            result,
            XCTestPlanInfo(
                name: name,
                selectedTests: [],
                skippedTests: [
                    "UITests/AdditionalOrderTest/testCheckAdditionalOrderCatalogActions()",
                    "UITests/AdditionalOrderTest/testCheckAdditionalOrderIsNotPossible()",
                ]
            )
        )
    }

    func test_onlySelectedTests_parsedCorrectly() throws {
        // given
        let name = UUID().uuidString
        let path = AbsolutePath.random(lastComponent: name + ".xctestplan")
        let data = try Bundle.module.readStubData(path: "TestPlanWithSelectedTests.json")

        filesManager.given(.readData(.value(path), log: .any, willReturn: data))

        // when
        let result = try parser.parseTestPlan(path: path)

        // then
        XCTAssertEqual(
            result,
            XCTestPlanInfo(
                name: name,
                selectedTests: [
                    "SOMERANDOMUITests/PickupTest/testCheckAlcoholAgeInfoInFavouriteAndOrder()",
                    "SOMERANDOMUITests/PickupTest/testCheckAlcoholAgeNotConfirmedAndCancelOrderNotAlcoholShip()",
                    "SOMERANDOMUITests/PickupTest/testCheckPickupActions()",
                ],
                skippedTests: []
            )
        )
    }
}
