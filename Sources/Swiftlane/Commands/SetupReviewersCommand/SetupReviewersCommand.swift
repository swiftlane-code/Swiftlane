
import ArgumentParser
import Foundation
import SwiftlaneCore

public protocol SetupReviewersCommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }
    var configPath: AbsolutePath { get }
}

/// CLI command to change status in jira issue
public struct SetupReviewersCommand: ParsableCommand, SetupReviewersCommandParamsAccessing {
    public static var configuration = CommandConfiguration(
        commandName: "setup-reviewers",
        abstract: "Parse config and update reviewers in Merge Request"
    )

    @OptionGroup public var sharedConfigOptions: SharedConfigOptions

    @Option(
        name: [.customLong("config")],
        help: "Path to config.yml"
    )
    public var configPath: AbsolutePath

    public init() {}

    public mutating func run() throws {
        SetupReviewersCommandRunner().run(self, sharedConfigOptions: sharedConfigOptions, commandConfigPath: configPath)
    }
}
