//

import Foundation
import SwiftlaneCore
import SwiftlaneCoreMocks
import SwiftlaneUnitTestTools
import SwiftyMocky
import SwiftyMockyXCTest
import XCTest

@testable import Simulator

protocol AutoMockable {}

class SimulatorProviderTests: XCTestCase {
    var simulatorProvider: SimulatorProvider!
    var logger: LoggingMock!
    var shell: ShellExecutingMock!
    var runtimesMiner: RuntimesMiningMock!

    override func setUp() {
        super.setUp()

        logger = LoggingMock()
        shell = ShellExecutingMock()
        runtimesMiner = RuntimesMiningMock()
        simulatorProvider = SimulatorProvider(
            runtimesMiner: runtimesMiner,
            shell: shell,
            logger: logger
        )
    }

    override func tearDown() {
        super.tearDown()
    }

    func test_failsOnRuntimesQueryThrowing() {
        let throwingError = TestError.some
        runtimesMiner.given(.getAll(willThrow: throwingError))

        XCTAssertThrowsError(try simulatorProvider.getAllDevices(), error: throwingError)
    }

    func test_failsOnDevicesQueryResultEmpty() {
        runtimesMiner.given(.getAll(willReturn: []))
        shell.given(
            .run(
                command: .any,
                options: .any,
                file: .any,
                line: .any,
                willReturn: .init(stdoutText: nil, stderrText: nil)
            )
        )

        let expectingError = SimulatorError.nilShOutput
        XCTAssertThrowsError(try simulatorProvider.getAllDevices(), error: expectingError)
    }

    func test_throwsNoDevicesErrorOnEmptyRuntimes() throws {
        runtimesMiner.given(.getAll(willReturn: []))

        let devicesResponse = try loadJsonFromBundle(name: "devices")
        shell.given(
            .run(
                command: .any,
                options: .any,
                file: .any,
                line: .any,
                willReturn: .init(stdoutText: devicesResponse, stderrText: nil)
            )
        )

        XCTAssertThrowsError(try simulatorProvider.getAllDevices(), error: SimulatorError.noDevicesFound)
    }

    func test_throwsNoDevicesErrorOnEmptyDevices() throws {
        let abstractRuntime = SimCtlRuntime(
            identifier: #function,
            name: #function,
            platform: #function,
            version: #function,
            buildversion: #function,
            isAvailable: true
        )

        runtimesMiner.given(.getAll(willReturn: [abstractRuntime]))

        let devicesResponse = "{\"devices\": {}}"
        shell.given(
            .run(
                command: .any,
                options: .any,
                file: .any,
                line: .any,
                willReturn: .init(stdoutText: devicesResponse, stderrText: nil)
            )
        )

        XCTAssertThrowsError(try simulatorProvider.getAllDevices(), error: SimulatorError.noDevicesFound)
    }

    func test_returnsSimulators() throws {
        let abstractRuntime = SimCtlRuntime(
            identifier: "com.apple.CoreSimulator.SimRuntime.watchOS-7-2",
            name: #function,
            platform: #function,
            version: #function,
            buildversion: #function,
            isAvailable: true
        )

        runtimesMiner.given(.getAll(willReturn: [abstractRuntime]))

        let devicesResponse = try loadJsonFromBundle(name: "devices")
        shell.given(
            .run(
                command: .any,
                options: .any,
                file: .any,
                line: .any,
                willReturn: .init(stdoutText: devicesResponse, stderrText: nil)
            )
        )

        let simulators = try simulatorProvider.getAllDevices()

        /// ``Simulator`` is not ``Equatable`` because of it's dependencies so we compare their ``udid``s.
        let udids = Set(simulators.map(\.device.udid))
        let expectingUDIDs = Set([
            "E03A59F1-4A3C-4A73-8382-F01695E9C23A",
            "3AFD8364-EF85-4D15-9140-52BD1C995893",
            "5B3F17AF-FD6C-4992-92E7-43331F0916C4",
            "A033997A-CEA5-4FB2-814D-0A48E8E209E0",
        ])

        XCTAssertEqual(udids, expectingUDIDs)
    }
}

private extension SimulatorProviderTests {
    /// `name` should be without extension.
    func loadJsonFromBundle(name jsonFileName: String) throws -> String {
        try Bundle.module.readStubText(path: jsonFileName + ".json")
    }
}
