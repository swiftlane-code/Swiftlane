//

import Foundation
import SwiftlaneCore
import SwiftlaneCoreMocks
import SwiftlaneUnitTestTools
import XCTest

@testable import Xcodebuild

class XCTestRunParserTests: XCTestCase {
    var parser: XCTestRunParser!

    var filesManager: FSManagingMock!
    var xcTestRunFinder: XCTestRunFindingMock!

    override func setUp() {
        super.setUp()

        filesManager = FSManagingMock()
        xcTestRunFinder = XCTestRunFindingMock()

        parser = XCTestRunParser(
            filesManager: filesManager,
            xcTestRunFinder: xcTestRunFinder
        )
    }

    override func tearDown() {
        xcTestRunFinder = nil
        filesManager = nil

        super.tearDown()
    }

    func test_parseWrongFileExtension_throwsError() throws {
        // given
        let path = try AbsolutePath("/derived_data/Build/Products".appendingPathComponent(name + ".wrongExt"))

        // when & then
        XCTAssertThrowsError(
            try parser.parseXCTestPaths(xcTestRunPath: path)
        ) { error in
            guard let parserError = error as? XCTestRunParser.Errors else {
                XCTFail("Unexpected error type: \(String(reflecting: error))")
                return
            }
            switch parserError {
            case .notXCTestRunFile(path.string):
                break
            default:
                XCTFail("Unexpected parser error type: \(String(reflecting: parserError))")
            }
        }
    }

    func test_parseXCTestRunWithoutXCTestPaths_throwsError() throws {
        // given
        let name = UUID().uuidString
        let path = try AbsolutePath("/derived_data/Build/Products".appendingPathComponent(name + ".xctestrun"))

        let xcTestRunContents = try xctestRunStubData(name: "NoXCTestPaths")

        filesManager.given(.readData(.value(path), log: .any, willReturn: xcTestRunContents))

        // when & then
        XCTAssertThrowsError(
            try parser.parseXCTestPaths(xcTestRunPath: path)
        ) { error in
            guard let parserError = error as? XCTestRunParser.Errors else {
                XCTFail("Unexpected error type: \(String(reflecting: error))")
                return
            }
            switch parserError {
            case .noXCTestPathsFound:
                break
            default:
                XCTFail("Unexpected parser error type: \(String(reflecting: parserError))")
            }
        }
    }

    func test_singleXCTestPath_fromTestPlanXCTestRun_parsedCorrectly() throws {
        // given
        let name = UUID().uuidString
        let path = try AbsolutePath("/derived_data/Build/Products".appendingPathComponent(name + ".xctestrun"))

        let xcTestRunContents = try xctestRunStubData(name: "SelectedTestsTestPlan")

        filesManager.given(.readData(.value(path), log: .any, willReturn: xcTestRunContents))

        // when
        let result = try parser.parseXCTestPaths(xcTestRunPath: path)

        // then
        XCTAssertEqual(
            result.map(\.string),
            ["/derived_data/Build/Products/Debug-iphonesimulator/SCUITests-Runner.app/PlugIns/SCUITests.xctest"]
        )
    }

    func test_singleXCTestPath_fromAnotherTestPlanXCTestRun_parsedCorrectly() throws {
        // given
        let name = UUID().uuidString
        let path = try AbsolutePath("/derived_data/Build/Products".appendingPathComponent(name + ".xctestrun"))

        let xcTestRunContents = try xctestRunStubData(name: "SkippedTestsTestPlan")

        filesManager.given(.readData(.value(path), log: .any, willReturn: xcTestRunContents))

        // when
        let result = try parser.parseXCTestPaths(xcTestRunPath: path)

        // then
        XCTAssertEqual(
            result.map(\.string),
            ["/derived_data/Build/Products/Debug-iphonesimulator/SCUITests-Runner.app/PlugIns/SCUITests.xctest"]
        )
    }

    func test_multipleXCTestPaths_parsedCorrectly() throws {
        // given
        let name = UUID().uuidString
        let path = try AbsolutePath("/derived_data/Build/Products".appendingPathComponent(name + ".xctestrun"))

        let xcTestRunContents = try xctestRunStubData(name: "SMUnitTests")

        filesManager.given(.readData(.value(path), log: .any, willReturn: xcTestRunContents))

        // when
        let result = try parser.parseXCTestPaths(xcTestRunPath: path)

        // then
        XCTAssertEqual(
            result.map(\.string),
            [
                "/derived_data/Build/Products/Debug-iphonesimulator/SCAnalyticsTests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/SCApeTests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/SCBavariTests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/SCBenchTests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/SCCSLayerTests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/SCCoreTests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/SCEarlyModeTests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/SCGeeksTests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/SCGreetingsTests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/SCInfraTests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/SCKitTests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/SCLSCTests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/SCLinksTests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/SCLoansTests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/SCMealTests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/SCPIATests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/SCPropersTests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/SCQutiesTests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/SCRollsTests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/SCRunTests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/SCTargetsTests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/SCUXStaffTests.xctest",
                "/derived_data/Build/Products/Debug-iphonesimulator/supercompany.app/PlugIns/supercompanyTests.xctest",
            ]
        )
    }
}

private func xctestRunStubData(name: String) throws -> Data {
    try Bundle.module.readStubData(path: "xctestruns/\(name).xctestrun")
}
