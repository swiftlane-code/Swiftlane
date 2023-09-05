//

import ArgumentParser
import Foundation
import SwiftlaneCore

public protocol ArchiveAndExportIPACommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }

    var scheme: String { get }
    var buildConfiguration: String { get }
    var ipaName: String { get }
    var provisioningProfileNamesForBundleIDs: [String: String] { get }
    var compileBitcode: Bool { get }
    var exportMethod: String { get }
}

// swiftformat:disable indent
public struct ArchiveAndExportIPACommand: ParsableCommand, ArchiveAndExportIPACommandParamsAccessing {
	public static var configuration = CommandConfiguration(
	    commandName: "archive-and-export-ipa",
	    abstract: "Build .xcarchive and export .ipa."
	)

	@OptionGroup public var sharedConfigOptions: SharedConfigOptions

	// MARK: Build config

	@Option(help: "Scheme to build.")
	public var scheme: String

	@Option(help: "Build configuration. Common ones are 'Debug' and 'Release'.")
	public var buildConfiguration: String

	@Option(help: "Name of exported .ipa file.")
	public var ipaName: String

	@Option(
		help: ArgumentHelp(
			"For manual signing. Bundle ID and its Provisioning profile name separated by ':'. " +
			"Example: 'com.my.app:myapp adhoc profile'. " +
			"Can be specified multiple times for multiple targets."
		)
	)
	public var bundleidProvisionProfileName: [ExpressibleByArgumentKeyValuePair] = []
	public var provisioningProfileNamesForBundleIDs: [String: String] {
		bundleidProvisionProfileName.reduce(into: [:]) { result, entry in
			result[entry.key] = entry.value
		}
	}

	@Option(help: "Should Xcode re-compile the app from bitcode?")
	public var compileBitcode: Bool = false

	@Option(help: "Export method ('ad-hoc', 'app-store').")
	public var exportMethod: String

	public init() {}

	public mutating func run() throws {
		ArchiveAndExportIPACommandRunner().run(self, sharedConfigOptions: sharedConfigOptions)
	}
}

// swiftformat:enable indent

/// Parsed from string like `"key:some value"`
public struct ExpressibleByArgumentKeyValuePair: ExpressibleByArgument {
    public let key: String
    public let value: String

    public init?(argument: String) {
        let parts = argument.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2 else {
            return nil
        }
        key = String(parts[0]).trimmingCharacters(in: .whitespaces)
        value = String(parts[1]).trimmingCharacters(in: .whitespaces)
    }
}
