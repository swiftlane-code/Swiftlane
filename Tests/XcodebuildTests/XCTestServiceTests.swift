//

import Foundation
import SwiftlaneCore
import XCTest

@testable import Xcodebuild

class XCTestServiceTests: XCTestCase {
    var service: XCTestService!

    var xctestParser: XCTestParsingMock!
    var xcTestRunFinder: XCTestRunFindingMock!
    var xcTestRunParser: XCTestRunParsingMock!

    override func setUp() {
        super.setUp()

        xctestParser = XCTestParsingMock()
        xcTestRunFinder = XCTestRunFindingMock()
        xcTestRunParser = XCTestRunParsingMock()

        service = XCTestService(
            xctestParser: xctestParser,
            xcTestRunFinder: xcTestRunFinder,
            xcTestRunParser: xcTestRunParser
        )
    }

    override func tearDown() {
        service = nil

        xcTestRunParser = nil
        xcTestRunFinder = nil
        xctestParser = nil

        super.tearDown()
    }

    func test_parseWrongFileExtension_throwsError() throws {
        // given
        let derivedDataPath = AbsolutePath.random()
        let xcTestRunPath = AbsolutePath.random()
        let xcTestPaths = [AbsolutePath.random(), AbsolutePath.random()]
        let compiledTestFunctions = [
            ["xyz", "def", "123", "_123", "func"],
            [UUID().uuidString, UUID().uuidString, "abc"],
        ]

        xcTestRunFinder.given(
            .findXCTestRunFile(
                derivedDataPath: .value(derivedDataPath),
                willReturn: xcTestRunPath
            )
        )
        xcTestRunParser.given(
            .parseXCTestPaths(
                xcTestRunPath: .value(xcTestRunPath),
                willReturn: xcTestPaths
            )
        )
        xctestParser.given(
            .parseCompiledTestFunctions(
                xctestPath: .value(xcTestPaths[0]),
                willReturn: compiledTestFunctions[0]
            )
        )
        xctestParser.given(
            .parseCompiledTestFunctions(
                xctestPath: .value(xcTestPaths[1]),
                willReturn: compiledTestFunctions[1]
            )
        )

        // when
        let result = try service.parseTests(derivedDataPath: derivedDataPath).await(timeout: 5)

        // then
        XCTAssertEqual(result.map(\.name), compiledTestFunctions.flatMap { $0 }.sorted())
    }
}
