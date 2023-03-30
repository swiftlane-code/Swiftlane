//

import Foundation
import SwiftlaneCore

/*
 https://www.iosdev.recipes/simctl/
 */

// sourcery: AutoMockable
public protocol SimulatorProtocol {
    var device: SimCtlDevice { get }
    var runtime: SimCtlRuntime { get }
    func boot() throws
    func shutdown() throws
    func erase() throws
    func disableSlideToType() throws
    func uninstallApp(identifier: String) throws

    /// Create a clone of existing simulator.
    /// - Parameters:
    ///   - name: name of the clone.
    ///   - erase: erase clone after creation.
    /// - Returns: new (cloned) simulator.
    func clone(withName name: String, andErase erase: Bool) throws -> Simulator
    func deleteSimulator() throws
    static func shutdownAll(shell: ShellExecuting) throws
}

public struct Simulator: SimulatorProtocol {
    public enum CloneError: Error {
        case cloneCommandDidNotReturnUDID
        case cloneCommandReturnedInvalidUDID
        case simulatorWithClonedUDIDNotFound
    }

    let simulatorProvider: SimulatorProviding
    public let device: SimCtlDevice
    public let runtime: SimCtlRuntime
    let shell: ShellExecuting
    let logger: Logging

    public var shortDescription: String {
        "\(device.name) (os: \(runtime.name), udid: \(device.udid)"
    }

    public func boot() throws {
        _ = try shell.run("xcrun simctl boot \(device.udid)", log: .silent)
    }

    public static func shutdownAll(shell: ShellExecuting) throws {
        _ = try shell.run("xcrun simctl shutdown all", log: .silent)
    }

    public func shutdown() throws {
        /// TODO: Uncomment later. Keep in mind that `simulator.state` may be out of date.
        //		if device.state == .shutdown {
        //			logger.log("The simuator \(device.name) (\(runtime.name)) is already in shutdown state.")
        //			return
        //		}
        _ = try shell.run(
            "xcrun simctl shutdown \(device.udid)",
            log: .silent,
            shouldIgnoreNonZeroExitCode: { output, _ in
                output.stderrText?.contains("Unable to shutdown device in current state: Shutdown") == true
            }
        )
    }

    public func erase() throws {
        try shutdown()
        _ = try shell.run("xcrun simctl erase \(device.udid)", log: .silent)
    }

    public func disableSlideToType() throws {
        guard runtime.platform == "iOS" else {
            return
        }

        let version = try (try? SemVer(parseFrom: runtime.version))
            .unwrap(
                errorDescription: "Runtime version \(runtime.version.quoted) is not a valid SemVer (of simulator \(shortDescription))."
            )

        guard version >= SemVer(13, 0, 0) else {
            return
        }

        let plist_buddy = "/usr/libexec/PlistBuddy"
        let plist_buddy_cmd = "-c \"Add :KeyboardContinuousPathEnabled bool false\""
        let plist_path = device.dataPath.appendingPathComponent(
            "Library/Preferences/com.apple.keyboard.ContinuousPath.plist"
        )

        _ = try shell.run("\(plist_buddy) \(plist_buddy_cmd) \(plist_path) >/dev/null 2>&1", log: .silent)
    }

    public func uninstallApp(identifier: String) throws {
        _ = try shell.run("xcrun simctl uninstall \(device.udid) \(identifier)", log: .silent)
    }

    /// Create a clone of existing simulator.
    /// - Parameters:
    ///   - name: name of the clone.
    ///   - erase: erase clone after creation.
    /// - Returns: new (cloned) simulator.
    public func clone(withName name: String, andErase erase: Bool) throws -> Simulator {
        logger.info("Cloning device: \(device.name) (\(runtime.name)) with new name: \(name)...")

        let cloneOutput = try shell.run("xcrun simctl clone \(device.udid) \"\(name)\"", log: .silent)

        guard let clonedUDID = cloneOutput.stdoutText?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw CloneError.cloneCommandDidNotReturnUDID
        }

        guard UUID(uuidString: clonedUDID) != nil else {
            throw CloneError.cloneCommandReturnedInvalidUDID
        }

        guard let clonedSim = try simulatorProvider.getAllDevices().first(where: { $0.device.udid == clonedUDID }) else {
            throw CloneError.simulatorWithClonedUDIDNotFound
        }

        if erase {
            try clonedSim.erase()
        }

        return clonedSim
    }

    public func deleteSimulator() throws {
        _ = try shell.run("xcrun simctl delete \(device.udid)", log: .silent)
    }
}
