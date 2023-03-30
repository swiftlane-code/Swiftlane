//

import ArgumentParser
import Foundation
import Guardian
import SwiftlaneCore
import Yams

public protocol GuardianAfterBuildCommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }
    var configPath: AbsolutePath { get }
    var unitTestsExitCode: Int { get }
}

/// CLI command to run Guardian After build.
public struct GuardianAfterBuildCommand: ParsableCommand, GuardianAfterBuildCommandParamsAccessing {
    public static var configuration = CommandConfiguration(
        commandName: "guardian-after-build",
        abstract: "Report any occured errors during building or running tests and validate code coverage limits."
    )

    @OptionGroup public var sharedConfigOptions: SharedConfigOptions

    @Option(
        name: [.customLong("config")],
        help: "Path to config.yml"
    )
    public var configPath: AbsolutePath

    @Option(help: "Unit tests exit code")
    public var unitTestsExitCode: Int

    public init() {}

    public mutating func run() throws {
        GuardianAfterBuildCommandRunner().run(
            self,
            sharedConfigOptions: sharedConfigOptions,
            commandConfigPath: configPath
        )
    }
}
