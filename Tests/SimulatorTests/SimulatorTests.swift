//

import Foundation
import SwiftlaneCore
import SwiftlaneCoreMocks
import XCTest

@testable import Simulator

class SimulatorTests: XCTestCase {
    var simulatorProviderMock: SimulatorProvidingMock!
    var shellMock: ShellExecutingMock!

    override func setUp() {
        super.setUp()

        simulatorProviderMock = SimulatorProvidingMock()
        shellMock = ShellExecutingMock()
    }

    override func tearDown() {
        super.tearDown()

        shellMock = nil
        simulatorProviderMock = nil
    }

    func test_shutdownAll() throws {
        // given
        shellMock.given(
            .run(
                command: .value("xcrun simctl shutdown all"),
                options: .any,
                file: .any,
                line: .any,
                willReturn: ShellOutput(stdoutText: nil, stderrText: nil)
            )
        )

        // when
        try Simulator.shutdownAll(shell: shellMock)
    }

    func test_boot() throws {
        // given
        let sim = simulatorStub()

        shellMock.given(
            .run(
                command: .value("xcrun simctl boot \(sim.device.udid)"),
                options: .any,
                file: .any,
                line: .any,
                willReturn: ShellOutput(stdoutText: nil, stderrText: nil)
            )
        )

        // when
        try sim.boot()
    }

    func test_shutdown() throws {
        // given
        let sim = simulatorStub()

        shellMock.given(
            .run(
                command: .value("xcrun simctl shutdown \(sim.device.udid)"),
                options: .any,
                file: .any,
                line: .any,
                willReturn: ShellOutput(stdoutText: nil, stderrText: nil)
            )
        )

        // when
        try sim.shutdown()
    }

    func test_erase() throws {
        // given
        let sim = simulatorStub()

        shellMock.given(
            .run(
                command: .value("xcrun simctl shutdown \(sim.device.udid)"),
                options: .any,
                file: .any,
                line: .any,
                willReturn: ShellOutput(stdoutText: nil, stderrText: nil)
            )
        )
        shellMock.given(
            .run(
                command: .value("xcrun simctl erase \(sim.device.udid)"),
                options: .any,
                file: .any,
                line: .any,
                willReturn: ShellOutput(stdoutText: nil, stderrText: nil)
            )
        )

        // when
        try sim.erase()
    }

    func test_delete() throws {
        // given
        let sim = simulatorStub()

        shellMock.given(
            .run(
                command: .value("xcrun simctl delete \(sim.device.udid)"),
                options: .any,
                file: .any,
                line: .any,
                willReturn: ShellOutput(stdoutText: nil, stderrText: nil)
            )
        )

        // when
        try sim.deleteSimulator()
    }

    func test_uninstall() throws {
        // given
        let sim = simulatorStub()
        let appID = "fake.app.id"

        shellMock.given(
            .run(
                command: .value("xcrun simctl uninstall \(sim.device.udid) \(appID)"),
                options: .any,
                file: .any,
                line: .any,
                willReturn: ShellOutput(stdoutText: nil, stderrText: nil)
            )
        )

        // when
        try sim.uninstallApp(identifier: appID)
    }

    func test_clone() throws {
        // given
        let sim = simulatorStub()
        let clonedName = "Cloned sim name"
        let clonedSim = simulatorStub()
        let clonedUDID = clonedSim.device.udid

        shellMock.given(
            .run(
                command: .value("xcrun simctl clone \(sim.device.udid) \(clonedName.quoted)"),
                options: .any,
                file: .any,
                line: .any,
                willReturn: ShellOutput(stdoutText: clonedUDID, stderrText: nil)
            )
        )

        simulatorProviderMock.given(
            .getAllDevices(
                willReturn: [sim, clonedSim]
            )
        )

        /// stubs for `clonedSim.erase()`
        shellMock.given(
            .run(
                command: .value("xcrun simctl shutdown \(clonedSim.device.udid)"),
                options: .any,
                file: .any,
                line: .any,
                willReturn: ShellOutput(stdoutText: nil, stderrText: nil)
            )
        )
        shellMock.given(
            .run(
                command: .value("xcrun simctl erase \(clonedSim.device.udid)"),
                options: .any,
                file: .any,
                line: .any,
                willReturn: ShellOutput(stdoutText: nil, stderrText: nil)
            )
        )

        // when
        let returnedClonedSim = try sim.clone(withName: clonedName, andErase: true)

        // then
        XCTAssertEqual(returnedClonedSim.device.udid, clonedSim.device.udid)
    }

    func test_disableSlideToType() throws {
        // given
        let sim = simulatorStub()

        shellMock.given(
            .run(
                command: .value(
                    "/usr/libexec/PlistBuddy -c \"Add :KeyboardContinuousPathEnabled bool false\" \(sim.device.dataPath)/Library/Preferences/com.apple.keyboard.ContinuousPath.plist >/dev/null 2>&1"
                ),
                options: .any,
                file: .any,
                line: .any,
                willReturn: ShellOutput(stdoutText: nil, stderrText: nil)
            )
        )

        // when
        try sim.disableSlideToType()
    }

    private func simulatorStub() -> Simulator {
        let logger = LoggingMock()
        logger.given(.logLevel(getter: .verbose))
        return Simulator(
            simulatorProvider: simulatorProviderMock,
            device: .stub,
            runtime: .stub,
            shell: shellMock,
            logger: logger
        )
    }
}

private extension SimCtlDevice {
    static var stub: SimCtlDevice {
        SimCtlDevice(
            dataPath: "FAKE_DATA_PATH",
            logPath: "log",
            udid: UUID().uuidString,
            isAvailable: true,
            deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-11",
            state: .shutdown,
            name: "Mocked iPhone"
        )
    }
}

private extension SimCtlRuntime {
    static var stub: SimCtlRuntime {
        SimCtlRuntime(
            identifier: "com.apple.CoreSimulator.SimRuntime.iOS-14-5",
            name: "iOS 14.5",
            platform: "iOS",
            version: "14.5",
            buildversion: "18E182",
            isAvailable: true
        )
    }
}
