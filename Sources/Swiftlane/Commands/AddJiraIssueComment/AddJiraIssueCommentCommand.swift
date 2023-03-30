
import ArgumentParser
import Foundation
import SwiftlaneCore

public protocol AddJiraIssueCommentCommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }
    var configPath: AbsolutePath { get }
    var text: String { get }
}

/// CLI command to add a comment to jira issue
public struct AddJiraIssueCommentCommand: ParsableCommand, AddJiraIssueCommentCommandParamsAccessing {
    public static var configuration = CommandConfiguration(
        commandName: "add-jira-issue-comment",
        abstract: "Add a comment to Jira issue."
    )

    @OptionGroup public var sharedConfigOptions: SharedConfigOptions

    @Option(
        name: [.customLong("config")],
        help: "Path to config.yml"
    )
    public var configPath: AbsolutePath

    @Option(help: "Comment text.")
    public var text: String

    public init() {}

    public mutating func run() throws {
        AddJiraIssueCommentCommandRunner().run(self, sharedConfigOptions: sharedConfigOptions, commandConfigPath: configPath)
    }
}
