//

import ArgumentParser
import Foundation
import SwiftlaneCore

public protocol UploadToFirebaseCommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }

    var ipaPath: AbsolutePath { get }
    var releaseNotes: String? { get }
    var testersEmails: String { get }
    var testersGroupsAliases: String { get }
    var firebaseToken: SensitiveData<String> { get }
    var firebaseAppID: String { get }
}

// swiftformat:disable indent
public struct UploadToFirebaseCommand: ParsableCommand, UploadToFirebaseCommandParamsAccessing {
	public static var configuration = CommandConfiguration(
	    commandName: "upload-to-firebase",
	    abstract: "Upload .ipa to Firebase App Distribution."
	)

	@OptionGroup public var sharedConfigOptions: SharedConfigOptions

	@Option(help: "Path to .ipa file.")
	public var ipaPath: AbsolutePath

	@Option(
		help: ArgumentHelp(
			stringLiteral:
		"Release notes. In case it's omitted Swiftlane will look for Jira issues in " +
		"commit/merge-request message and list summaries of found Jira issues."
		)
	)
	public var releaseNotes: String?

	@Option(
		help: "Comma (,) separated list of testers emails to ditribute the release to. Can be empty string (or omitted)."
	)
	public var testersEmails: String = ""

	@Option(help: "Comma (,) separated list of testers groups to ditribute the release to. Can be empty string.")
	public var testersGroupsAliases: String

	@Option(
		help: "Can be obtained in Firebase CLI tools using command \"login:ci\". https://firebase.google.com/docs/cli#cli-ci-systems"
	)
	public var firebaseToken: SensitiveData<String>

	@Option(help: "Your App ID in Firebase Console. You can find it in 'Firebase Console' -> 'Project Settings'.")
	public var firebaseAppID: String

	public init() {}

	public mutating func run() throws {
		UploadToFirebaseCommandRunner().run(self, sharedConfigOptions: sharedConfigOptions)
	}
}

// swiftformat:enable indent
