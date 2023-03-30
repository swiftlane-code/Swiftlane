
import ArgumentParser
import Foundation
import SwiftlaneCore

public protocol SetupLabelsCommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }
    var configPath: AbsolutePath { get }
}

/// CLI command to change status in jira issue
public struct SetupLabelsCommand: ParsableCommand, SetupLabelsCommandParamsAccessing {
    public static var configuration = CommandConfiguration(
        commandName: "setup-labels",
        abstract: "Parse config and update labels in Merge Request"
    )

    @OptionGroup public var sharedConfigOptions: SharedConfigOptions

    @Option(
        name: [.customLong("config")],
        help: "Path to config.yml"
    )
    public var configPath: AbsolutePath

    public init() {}

    public mutating func run() throws {
        SetupLabelsCommandRunner().run(self, sharedConfigOptions: sharedConfigOptions, commandConfigPath: configPath)
    }
}
