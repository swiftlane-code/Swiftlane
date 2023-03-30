//

import AppStoreConnectAPI
import ArgumentParser
import Foundation
import SwiftlaneCore
import Yams

public protocol ReportUnusedCodeCommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }

    var reportedFile: [RelativePath] { get }

    var ignoreTypeName: [String] { get }
    var mattermostApiURL: URL? { get }
    var mattermostWebhookKey: String? { get }
    var build: Bool { get }
}

// swiftformat:disable indent
public struct ReportUnusedCodeCommand: ParsableCommand, ReportUnusedCodeCommandParamsAccessing {
	public static var configuration = CommandConfiguration(
	    commandName: "report-unused-code",
	    abstract: "Scan project for unused code in specific files. " +
			"Report is generated in form of .md file inside results directory.",
	    discussion: "This command requires periphery https://github.com/peripheryapp/periphery"
	)

	@OptionGroup public var sharedConfigOptions: SharedConfigOptions

	@Option(
		help: "Path to a swift file to report unused code in (relative to project dir). May be specified multiple times."
	)
	public var reportedFile: [RelativePath]

	@Option(help: "Name of a type to exclude from report. This option can be specified multiple times.")
	public var ignoreTypeName: [String] = []

	@Option(help: "Something like `https://your-mattermost-server.com`")
	public var mattermostApiURL: URL?

	@Option(
		help: ArgumentHelp(
			stringLiteral:
		"Webhook to post a summary of report including link to the job. Looks like `0a3cbff4ea09b63023b3e9bf92c6898`." +
		"\nIt is the last part of your full webhook url https://your-mattermost-server.com/hooks/0a3cbff4ea09b63023b3e9bf92c6898"
		)
	)
	public var mattermostWebhookKey: String?

	@Flag(help: "Do not pass --skip-build to periphery.")
	public var build: Bool = false

	public init() {}

	public mutating func run() throws {
		ReportUnusedCodeCommandRunner().run(self, sharedConfigOptions: sharedConfigOptions)
	}
}

// swiftformat:enable indent
