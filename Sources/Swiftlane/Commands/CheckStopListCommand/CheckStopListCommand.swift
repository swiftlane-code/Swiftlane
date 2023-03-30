
import ArgumentParser
import Foundation
import SwiftlaneCore

public protocol CheckStopListCommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }
    var configPath: AbsolutePath { get }
}

/// CLI command to change status in jira issue
public struct CheckStopListCommand: ParsableCommand, CheckStopListCommandParamsAccessing {
    public static var configuration = CommandConfiguration(
        commandName: "check-stop-list",
        abstract: "Checks for changes in files located in the `stop list`"
    )

    @OptionGroup public var sharedConfigOptions: SharedConfigOptions

    @Option(
        name: [.customLong("config")],
        help: "Path to config.yml"
    )
    public var configPath: AbsolutePath

    public init() {}

    public mutating func run() throws {
        CheckStopListCommandRunner().run(self, sharedConfigOptions: sharedConfigOptions, commandConfigPath: configPath)
    }
}
