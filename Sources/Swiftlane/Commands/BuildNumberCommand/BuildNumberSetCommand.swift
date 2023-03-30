//

import ArgumentParser
import Foundation
import SwiftlaneCore

public protocol BuildNumberSetCommandParamsAccessing {
    var options: BuildNumberCommandOptions { get }
    var sharedConfigOptions: SharedConfigOptions { get }

    var buildSettings: Bool { get }
    var infoPlist: Bool { get }
    var buildNumber: String { get }
}

// swiftformat:disable indent
public struct BuildNumberSetCommand: ParsableCommand, BuildNumberSetCommandParamsAccessing {
	public static var configuration = CommandConfiguration(
	    commandName: "set",
	    abstract: "Set provided build number."
	)

	@OptionGroup public var options: BuildNumberCommandOptions

	@OptionGroup public var sharedConfigOptions: SharedConfigOptions

	@Flag(help: "Set provided build number value to CFBundleVersion in Info.plist files.")
	public var buildSettings: Bool = false

	@Flag(help: "Set provided build number value to CURRENT_PROJECT_VERSION in build setting.")
	public var infoPlist: Bool = false

	@Argument(help: "Build Number to set.")
	public var buildNumber: String

	public init() {}

	public func validate() throws {
		guard infoPlist || buildSettings else {
			throw ValidationError("Missing one of required options: --info-plist or --buildSettings.")
		}
	}

	public mutating func run() throws {
		BuildNumberSetCommandRunner().run(self, sharedConfigOptions: sharedConfigOptions)
	}
}
