//

import AppStoreConnectAPI
import ArgumentParser
import Foundation
import SwiftlaneCore
import Yams

public protocol CertsInstallCommandParamsAccessing {
    var options: CertsCommandOptions { get }

    var commonOptions: CommonOptions { get }
    var additionalCertificates: String { get }
    var keychainPassword: SensitiveData<String>? { get }
    var forceReinstall: Bool { get }
    var authKeyOutputDirectory: AbsolutePath? { get }
}

// swiftformat:disable indent
public struct CertsInstallCommand: ParsableCommand, CertsInstallCommandParamsAccessing {
	public static var configuration = CommandConfiguration(
	    commandName: "install",
	    abstract: "Install certificates and provisioning profiles."
	)

	@OptionGroup public var options: CertsCommandOptions

	@Option(help: "Keychain password. Can be passed via \(CertsCommandConfig.keychainPasswordEnvKey)")
	public var keychainPassword: SensitiveData<String>?

	@Flag(help: "Force reinstall of certificates and private keys into keychain.")
	public var forceReinstall: Bool = false

  @Option(help: "Path to directory to copy decrypted AuthKey_XXXXXXX.p8 into.")
  public var authKeyOutputDirectory: AbsolutePath?

	@OptionGroup public var commonOptions: CommonOptions

	@Option(
		help: .init(
			"URLs of additional certificates to be installed separated by comma. \n" +
			"Note: AppleWWDRCAG3.cer is Developer Relations Intermediate Certificate which is the issuer of your codesigning certificates."
		)
	)
	public var additionalCertificates: String = "https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer"

	public init() {}

	public mutating func run() throws {
		CertsInstallCommandRunner().run(self, commandConfigPath: options.config, commonOptions: commonOptions)
	}
}

// swiftformat:enable indent
