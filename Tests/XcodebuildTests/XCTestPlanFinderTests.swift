//

import Foundation
import SwiftlaneCore
import SwiftlaneCoreMocks
import XCTest

@testable import Xcodebuild

class XCTestPlanFinderTests: XCTestCase {
    var finder: XCTestPlanFinder!

    var filesManager: FSManagingMock!
    var xcTestRunParser: XCTestRunParsingMock!
    var xcTestRunFinder: XCTestRunFindingMock!

    override func setUp() {
        super.setUp()

        filesManager = FSManagingMock()
        xcTestRunParser = XCTestRunParsingMock()
        xcTestRunFinder = XCTestRunFindingMock()

        finder = XCTestPlanFinder(
            filesManager: filesManager,
            xctestRunFinder: xcTestRunFinder,
            xcTestRunParser: xcTestRunParser
        )
    }

    override func tearDown() {
        filesManager = nil
        xcTestRunParser = nil
        xcTestRunFinder = nil

        super.tearDown()
    }

    func test_findXCTestPlans() throws {
        // given
        let derivedDataPath = AbsolutePath.random()
        let findXCTestRunFile = AbsolutePath.random()
        let xctestPaths = [AbsolutePath.random(), AbsolutePath.random()]

        xcTestRunFinder.given(
            .findXCTestRunFile(
                derivedDataPath: .value(derivedDataPath),
                willReturn: findXCTestRunFile
            )
        )

        xcTestRunParser.given(
            .parseXCTestPaths(
                xcTestRunPath: .value(findXCTestRunFile),
                willReturn: xctestPaths
            )
        )

        let xctestplanFile1 = AbsolutePath.random(suffix: ".xctestplan")
        let xctestplanFile2 = AbsolutePath.random(suffix: ".xctestplan")
        let xctestPaths_subpaths12 = [AbsolutePath.random(), xctestplanFile1, AbsolutePath.random(), xctestplanFile2]

        let xctestplanFile3 = AbsolutePath.random(suffix: ".xctestplan")
        let xctestPaths_subpaths3 = [AbsolutePath.random(), xctestplanFile3, AbsolutePath.random()]

        filesManager.given(
            .find(
                .value(xctestPaths[0]),
                file: .any,
                line: .any,
                willReturn: xctestPaths_subpaths12
            )
        )
        filesManager.given(
            .find(
                .value(xctestPaths[1]),
                file: .any,
                line: .any,
                willReturn: xctestPaths_subpaths3
            )
        )

        // when
        let result = try finder.findXCTestPlans(derivedDataPath: derivedDataPath)

        // then
        XCTAssertEqual(result, [xctestplanFile1, xctestplanFile2, xctestplanFile3])
    }
}
