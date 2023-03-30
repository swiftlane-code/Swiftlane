//

import Foundation
import SwiftlaneCore
import SwiftlaneCoreMocks
import SwiftlaneUnitTestTools
import XCTest

@testable import Xcodebuild

class XCTestPlanPatcherTests: XCTestCase {
    var patcher: XCTestPlanPatcher!

    var filesManager: FSManagingMock!
    var environmentReader: EnvironmentValueReadingMock!
    var logger: LoggingMock!

    override func setUp() {
        super.setUp()

        logger = LoggingMock()
        filesManager = FSManagingMock()
        environmentReader = EnvironmentValueReadingMock()

        patcher = XCTestPlanPatcher(
            logger: logger,
            filesManager: filesManager,
            environmentReader: environmentReader
        )

        logger.given(.logLevel(getter: .verbose))
    }

    override func tearDown() {
        filesManager = nil
        logger = nil
        environmentReader = nil

        patcher = nil

        super.tearDown()
    }

    func test_patchTestPlanWithoutEnvVariables_creates_environmentVariableEntries() throws {
        // given
        let planData = try Bundle.module.readStubData(path: "TestPlanWithoutEnvVariables.json")
        let expectedResult = try Bundle.module.readStubText(path: "TestPlanWithoutEnvVariablesPatched.json")

        // when
        let resultData = try patcher.patchEnvironmentVariables(data: planData, with: [
            "tp_var1": "value1",
            "tp_var_2": "value 2",
        ])

        // then
        let resultText = try String(data: resultData, encoding: .utf8).unwrap()

        print(resultText)
        XCTAssertEqual(resultText, expectedResult)
    }

    func test_patchTestPlanWithEnvVariables_patches_environmentVariableEntries() throws {
        // given
        let planData = try Bundle.module.readStubData(path: "TestPlanWithEnvVariables.json")
        let expectedResult = try Bundle.module.readStubText(path: "TestPlanWithEnvVariablesPatched.json")

        // when
        let resultData = try patcher.patchEnvironmentVariables(data: planData, with: [
            "tp_var1": "value1",
            "tp_var_2": "value 2",
        ])

        // then
        let resultText = try String(data: resultData, encoding: .utf8).unwrap()

        print(resultText)
        XCTAssertEqual(resultText, expectedResult)
    }
}
