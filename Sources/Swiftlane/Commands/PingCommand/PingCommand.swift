//

import ArgumentParser
import Foundation
import SwiftlaneCore

public struct PingCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "ping",
        abstract: "Useless command."
    )

    @OptionGroup public var commonOptions: CommonOptions

    public init() {}

    public func run() throws {
        print("[ping command] hi there!")

        Runner().run(self, commonOptions: commonOptions)
    }
}

private class Runner: CommandRunnerProtocol {
    public func run(
        params _: PingCommand,
        commandConfig _: Void,
        sharedConfig _: Void,
        logger: Logging
    ) throws {
        logger.error("logger.error")
        logger.warn("logger.warn")
        logger.important("logger.important")
        logger.info("logger.log")
        logger.debug("logger.debug")
        logger.verbose("logger.verbose")

        logger.logShellCommand("logger.logShellCommand somearg")
    }
}
