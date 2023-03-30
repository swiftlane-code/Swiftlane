//

import Foundation
import SwiftlaneCore
import SwiftlaneCoreMocks
import SwiftlaneUnitTestTools
import XCTest

@testable import Swiftlane

class WarningsStorageTests: XCTestCase {
    var storage: WarningsStorage!
    var filesManager: FSManagingMock!
    var config: WarningsStorage.Config!

    override func setUp() {
        super.setUp()

        filesManager = .init()

        config = .init(
            projectDir: .random(lastComponent: "projectDir"),
            warningsJsonsFolder: .random(lastComponent: "warningsJsonsFolder")
        )

        storage = WarningsStorage(
            filesManager: filesManager,
            config: config
        )
    }

    override func tearDown() {
        super.tearDown()

        storage = nil

        filesManager = nil
    }

    func test_readListOfDirectories() throws {
        // given

        filesManager.given(.find(.value(config.warningsJsonsFolder), file: .any, line: .any, willReturn: [
            try! config.warningsJsonsFolder.appending(path: "1.txt"),
            try! config.warningsJsonsFolder.appending(path: "2.txt"),
            try! config.warningsJsonsFolder.appending(path: "3.json"),
            try! config.warningsJsonsFolder.appending(path: "4.json"),
            try! config.warningsJsonsFolder.appending(path: "5.swift"),
            try! config.warningsJsonsFolder.appending(path: "6"),
        ]))

        // when
        let report = try storage.readListOfDirectories()

        // then
        XCTAssertEqual(report, ["3", "4"])
    }
//
    //	func test_readsJSON() throws {
    //		// given
    //		let data = try Bundle.module.readStubData(path: "swiftlint_warnings_1.json")
    //		let jsonName = "warnings_" + .random()
//
    //		filesManager.given(
    //			.readData(
    //				.value(try! config.warningsJsonsFolder.appending(path: "\(jsonName).json")),
    //				log: .any,
    //				willReturn: data
    //			)
    //		)
//
    //		// when
    //		let knownWarnings = try storage.read(jsonName: jsonName)
//
    //		// then
    //		XCTAssertEqual(knownWarnings.count, 12)
    //	}
//
    //	func test_savesJSON() throws {
    //		// given
    //		let data = try Bundle.module.readStubData(path: "swiftlint_warnings_1.json")
    //		let text = try Bundle.module.readStubText(path: "swiftlint_warnings_1.json")
    //		let jsonName = "warnings_" + .random()
    //		let path = try config.warningsJsonsFolder.appending(path: "\(jsonName).json")
//
    //		filesManager.given(.readData(.value(path), log: .any, willReturn: data))
    //		let knownWarnings = try storage.read(jsonName: jsonName)
//
    //		filesManager.resetMock()
//
    //		// when
    //		try storage.save(jsonName: jsonName, warnings: knownWarnings)
//
    //		// then
    //		filesManager.verify(.write(.value(path), text: .value(text)))
//
    //		XCTAssertEqual(knownWarnings.count, 12)
    //	}
}
