
import ArgumentParser
import Foundation
import SwiftlaneCore

public protocol ChangeJiraIssueLabelsCommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }
    var configPath: AbsolutePath { get }
    var neededLabels: [String] { get }
    var appendLabels: Bool { get }
}

/// CLI command to change status in jira issue
public struct ChangeJiraIssueLabelsCommand: ParsableCommand, ChangeJiraIssueLabelsCommandParamsAccessing {
    public static var configuration = CommandConfiguration(
        commandName: "change-jira-issue-labels",
        abstract: "Starts an attempt to change the JIRA task labels"
    )

    @OptionGroup public var sharedConfigOptions: SharedConfigOptions

    @Option(
        name: [.customLong("config")],
        help: "Path to config.yml"
    )
    public var configPath: AbsolutePath

    @Option(help: "Target labels to set JIRA issue into")
    public var neededLabels: [String]

    @Flag(help: "Append or replacement labels. Default false - this means replacing")
    public var appendLabels: Bool = false

    public init() {}

    public mutating func run() throws {
        ChangeJiraIssueLabelsCommandRunner().run(
            self,
            sharedConfigOptions: sharedConfigOptions,
            commandConfigPath: configPath
        )
    }
}
