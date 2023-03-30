//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
/// Allows to get available simulator runtimes.
public protocol RuntimesMining {
    func getAll() throws -> [SimCtlRuntime]
}

public struct RuntimesMiner {
    public init(shell: ShellExecuting) {
        self.shell = shell
    }

    let shell: ShellExecuting
}

extension RuntimesMiner: RuntimesMining {
    public func getAll() throws -> [SimCtlRuntime] {
        guard let jsonData = try shell.run(
            "xcrun simctl list runtimes --json",
            log: .commandAndOutput(outputLogLevel: .verbose),
            silentStdErrMessages: true
        ).stdoutText?.data(using: .utf8) else {
            throw SimulatorError.nilShOutput
        }

        struct Response: Decodable {
            let runtimes: [SimCtlRuntime]
        }

        let runtimes = try JSONDecoder().decode(Response.self, from: jsonData).runtimes

        if runtimes.isEmpty {
            throw SimulatorError.noRuntimesFound
        }

        // Sometimes "simctl" doesn't provide platform name for some reason
        // so we extract it from runtime's name.
        let fixedRuntimesPlatforms: [SimCtlRuntime] = runtimes.map {
            SimCtlRuntime(
                identifier: $0.identifier,
                name: $0.name,
                platform: $0.platform ?? $0.name.split(separator: " ").first.map(String.init),
                version: $0.version,
                buildversion: $0.buildversion,
                isAvailable: $0.isAvailable
            )
        }

        return fixedRuntimesPlatforms
    }
}
