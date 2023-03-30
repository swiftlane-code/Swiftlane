//

import Foundation
import SwiftlaneCore
import SwiftlaneCoreMocks
import XCTest

@testable import Xcodebuild

class XCTestRunFinderTests: XCTestCase {
    var finder: XCTestRunFinder!

    var filesManager: FSManagingMock!

    override func setUp() {
        super.setUp()

        filesManager = FSManagingMock()

        finder = XCTestRunFinder(
            filesManager: filesManager
        )
    }

    override func tearDown() {
        filesManager = nil

        super.tearDown()
    }

    func test_findXCTestRunFile() throws {
        // given
        let derivedDataPath = AbsolutePath.random()
        let xctestRunName = AbsolutePath.random(suffix: ".xctestrun")
        let subpaths = [AbsolutePath.random(), AbsolutePath.random(), xctestRunName]

        filesManager.given(
            .find(
                .value(derivedDataPath),
                file: .any,
                line: .any,
                willReturn: subpaths
            )
        )

        // when
        let result = try finder.findXCTestRunFile(derivedDataPath: derivedDataPath)

        // then
        XCTAssertEqual(result, xctestRunName)
    }
}
