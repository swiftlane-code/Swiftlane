//

import ArgumentParser
import Foundation
import SwiftlaneCore

public protocol GuardianBeforeBuildCommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }
    var configPath: AbsolutePath { get }
}

/// CLI command to run Guardian after build.
public struct GuardianBeforeBuildCommand: ParsableCommand, GuardianBeforeBuildCommandParamsAccessing {
    public static var configuration = CommandConfiguration(
        commandName: "guardian-before-build",
        abstract: "Run varoius checks before build such as warning limits, indentation using tabs etc."
    )

    @OptionGroup public var sharedConfigOptions: SharedConfigOptions

    @Option(
        name: [.customLong("config")],
        help: "Path to config.yml"
    )
    public var configPath: AbsolutePath

    public init() {}

    public mutating func run() throws {
        GuardianBeforeBuildCommandRunner().run(
            self,
            sharedConfigOptions: sharedConfigOptions,
            commandConfigPath: configPath
        )
    }
}
