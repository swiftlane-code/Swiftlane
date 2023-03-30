//

import AppStoreConnectAPI
import ArgumentParser
import Foundation
import SwiftlaneCore

public protocol UploadToAppStoreCommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }

    var ipaPath: AbsolutePath { get }
    var authKeyPath: AbsolutePath { get }
    var authKeyIssuerID: SensitiveData<String> { get }
    var manageAppVersionAndBuildNumber: Bool { get }
    var uploadTool: AppStoreConnectIPAUploaderType { get }
}

extension AppStoreConnectIPAUploaderType: ExpressibleByArgument {}

public struct UploadToAppStoreCommand: ParsableCommand, UploadToAppStoreCommandParamsAccessing {
    public static var configuration = CommandConfiguration(
        commandName: "upload-to-appstore",
        abstract: "Upload .ipa to App Store Connect."
    )

    @OptionGroup public var sharedConfigOptions: SharedConfigOptions

    @Option(help: "Path to .ipa file.")
    public var ipaPath: AbsolutePath

    @Option(help: "Path to your 'AuthKey_XXXXXXX.p8' file.")
    public var authKeyPath: AbsolutePath

    @Option(help: "Issuer ID for 'AuthKey_XXXXXXX.p8' file.")
    public var authKeyIssuerID: SensitiveData<String>

    @Option(help: "Should Xcode manage the app's build number when uploading to App Store Connect? Defaults to `false`.")
    public var manageAppVersionAndBuildNumber: Bool = false

    @Option(help: "Which upload tool to use.")
    public var uploadTool: AppStoreConnectIPAUploaderType = .iTMSTransporter

    public init() {}

    public mutating func run() throws {
        UploadToAppStoreCommandRunner().run(self, sharedConfigOptions: sharedConfigOptions)
    }
}
