//

import Foundation

import SwiftlaneCore

// sourcery: AutoMockable
public protocol SimulatorProviding {
    func getAllDevices() throws -> [Simulator]
}

public struct SimulatorProvider {
    let runtimesMiner: RuntimesMining
    let shell: ShellExecuting
    let logger: Logging

    public init(
        runtimesMiner: RuntimesMining,
        shell: ShellExecuting,
        logger: Logging
    ) {
        self.runtimesMiner = runtimesMiner
        self.shell = shell
        self.logger = logger
    }
}

extension SimulatorProvider: SimulatorProviding {
    public func getAllDevices() throws -> [Simulator] {
        let allRuntimes = try runtimesMiner.getAll()

        guard let devicesResponseData = try shell.run(
            "xcrun simctl list devices --json",
            log: .commandAndOutput(outputLogLevel: .verbose),
            silentStdErrMessages: true
        ).stdoutText?.data(using: .utf8) else {
            throw SimulatorError.nilShOutput
        }

        struct Response: Decodable {
            let devices: [String: [SimCtlDevice]]
        }

        let response = try JSONDecoder().decode(Response.self, from: devicesResponseData)

        let simulators = response.devices.flatMap { runtimeIdentifier, devices -> [Simulator] in
            guard let runtime = allRuntimes.first(where: { $0.identifier == runtimeIdentifier }) else {
                return []
            }
            return devices.map {
                Simulator(
                    simulatorProvider: self,
                    device: $0,
                    runtime: runtime,
                    shell: self.shell,
                    logger: self.logger
                )
            }
        }

        if simulators.isEmpty {
            throw SimulatorError.noDevicesFound
        }

        return simulators
    }
}
