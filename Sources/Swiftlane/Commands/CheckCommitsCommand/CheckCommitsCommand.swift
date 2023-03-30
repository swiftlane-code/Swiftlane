
import ArgumentParser
import Foundation
import SwiftlaneCore

public protocol CheckCommitsCommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }
    var configPath: AbsolutePath { get }
}

/// CLI command to change status in jira issue
public struct CheckCommitsCommand: ParsableCommand, CheckCommitsCommandParamsAccessing {
    public static var configuration = CommandConfiguration(
        commandName: "check-commits",
        abstract: "Checks for important commits on the HEAD"
    )

    @OptionGroup public var sharedConfigOptions: SharedConfigOptions

    @Option(
        name: [.customLong("config")],
        help: "Path to config.yml"
    )
    public var configPath: AbsolutePath

    public init() {}

    public mutating func run() throws {
        CheckCommitsCommandRunner().run(self, sharedConfigOptions: sharedConfigOptions, commandConfigPath: configPath)
    }
}
