
import ArgumentParser
import Foundation
import SwiftlaneCore

public protocol ChangeVersionCommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }
    var action: ChangeVersionCommand.Action { get }
}

public struct ChangeVersionCommand: ParsableCommand, ChangeVersionCommandParamsAccessing {
    public static var configuration = CommandConfiguration(
        commandName: "change-version",
        abstract: "Change current project version."
    )

    public enum Action: String, EnumerableFlag {
        case bumpMajor
        case bumpMinor
        case bumpPatch
    }

    @OptionGroup public var sharedConfigOptions: SharedConfigOptions

    @Flag(help: "What to do.")
    public var action: Action

    @Option(
        name: [.customLong("config")],
        help: "Path to config.yml"
    )
    public var configPath: AbsolutePath

    public init() {}

    public mutating func run() throws {
        ChangeVersionCommandRunner<StraightforwardProjectVersionConverter>()
            .run(self, sharedConfigOptions: sharedConfigOptions, commandConfigPath: configPath)
    }
}
