//

import Foundation
import XCTest

@testable import Swiftlane

class RangesWelderTests: XCTestCase {
    var welder: RangesWelder!

    override func setUp() {
        super.setUp()

        welder = .init()
    }

    override func tearDown() {
        super.tearDown()

        welder = nil
    }

    func test_weldRanges() {
        XCTAssertEqual(welder.weldRanges(
            from: [1, 2, 3, 4, 5]
        ), ["1...5"])

        XCTAssertEqual(welder.weldRanges(
            from: [10]
        ), ["10"])

        XCTAssertEqual(welder.weldRanges(
            from: [1, 2, 4, 5]
        ), ["1...2", "4...5"])

        XCTAssertEqual(welder.weldRanges(
            from: [1, 3, 4, 5]
        ), ["1", "3...5"])

        XCTAssertEqual(welder.weldRanges(
            from: [1, 3, 5]
        ), ["1", "3", "5"])

        XCTAssertEqual(welder.weldRanges(
            from: [1, 2, 3, 4, 5, 100, 200]
        ), ["1...5", "100", "200"])
    }
}
