//

import Foundation
import SwiftlaneCore

public class SimulatorLogsChecker {
    public struct Config {
        public let checkSimulatorsLogsScriptPath: AbsolutePath
    }

    public let shell: ShellExecuting
    public let config: Config

    public init(
        shell: ShellExecuting,
        config: Config
    ) {
        self.shell = shell
        self.config = config
    }

    public func check(systemLogsDir: AbsolutePath) throws {
        _ = try shell.run(
            "\(config.checkSimulatorsLogsScriptPath) '\(systemLogsDir)' '*.log'",
            log: .commandAndOutput(outputLogLevel: .debug)
        )
    }
}
