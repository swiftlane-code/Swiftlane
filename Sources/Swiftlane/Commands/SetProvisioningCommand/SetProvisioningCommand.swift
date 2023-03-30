//

import ArgumentParser
import Foundation
import SwiftlaneCore

public protocol SetProvisioningCommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }

    var scheme: String { get }
    var buildConfiguration: String { get }
    var provisionProfileName: String { get }
}

public struct SetProvisioningCommand: ParsableCommand, SetProvisioningCommandParamsAccessing {
    public static var configuration = CommandConfiguration(
        commandName: "set-provisioning-profile",
        abstract: "Set provisioning profile for a target based on scheme and build configuration."
    )

    @OptionGroup public var sharedConfigOptions: SharedConfigOptions

    @Option(help: "Scheme of target to set provisioning profile for.")
    public var scheme: String

    @Option(help: "Build configuration. Common ones are 'Debug' and 'Release'.")
    public var buildConfiguration: String

    @Option(
        help: "Provisioning profile name. The profile should be installed in '~/Library/MobileDevice/Provisioning Profiles/'."
    )
    public var provisionProfileName: String

    public init() {}

    public mutating func run() throws {
        SetProvisioningCommandRunner().run(self, sharedConfigOptions: sharedConfigOptions)
    }
}
