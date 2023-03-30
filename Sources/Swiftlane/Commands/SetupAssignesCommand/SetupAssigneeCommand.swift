
import ArgumentParser
import Foundation
import SwiftlaneCore

public protocol SetupAssigneeCommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }
    var configPath: AbsolutePath { get }
}

/// CLI command to change status in jira issue
public struct SetupAssigneeCommand: ParsableCommand, SetupAssigneeCommandParamsAccessing {
    public static var configuration = CommandConfiguration(
        commandName: "setup-assignee",
        abstract: "Added assignee by author in Merge Request"
    )

    @OptionGroup public var sharedConfigOptions: SharedConfigOptions

    @Option(
        name: [.customLong("config")],
        help: "Path to config.yml"
    )
    public var configPath: AbsolutePath

    public init() {}

    public mutating func run() throws {
        SetupAssigneeCommandRunner().run(self, sharedConfigOptions: sharedConfigOptions, commandConfigPath: configPath)
    }
}
