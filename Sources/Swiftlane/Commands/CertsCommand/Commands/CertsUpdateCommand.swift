//

import AppStoreConnectAPI
import ArgumentParser
import Bagbutik_Core
import Foundation
import Git
import Provisioning
import SwiftlaneCore
import Yams

extension ProvisionProfileType: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(rawValue: argument)
    }
}

public struct CertsUpdateCommand: ParsableCommand, CommandRunnerProtocol {
    public static var configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update certificates and provisioning profiles."
    )

    @OptionGroup public var globalOptions: SharedConfigOptions

    @OptionGroup public var options: CertsCommandOptions

    @Option(help: "Path to your 'AuthKey_XXXXXXX.p8' file.")
    public var authKeyPath: AbsolutePath

    @Option(help: "Issuer ID for 'AuthKey_XXXXXXX.p8' file.")
    public var authKeyIssuerID: SensitiveData<String>

    @Option(help: "App's bundle ID to update provisioning profiles for. This option can be specified multiple times.")
    public var bundleId: [String]

    @Option(help: "Provisioning profiles types to update. This option can be specified multiple times.")
    public var type: [ProvisionProfileType] = [.development, .adhoc, .appstore]

    public init() {}

    public mutating func run() throws {
        run(
            (),
            sharedConfigOptions: globalOptions,
            commandConfigPath: options.config
        )
    }

    public func verifyConfigs(
        params _: (),
        commandConfig _: CertsCommandConfig,
        sharedConfig _: SharedConfigData,
        logger: Logging
    ) throws -> Bool {
        if options.repoPassword == nil {
            logger.error("--repo-password option is not supplied. User will be prompted to enter password in runtime.")
            return false
        }
        return true
    }

    public func run(
        params _: Void,
        commandConfig: CertsCommandConfig,
        sharedConfig _: SharedConfigData,
        logger _: Logging
    ) throws {
        let passwordReader: PasswordReading = DependenciesFactory.resolve()

        let repoPassword = try options.repoPassword?.sensitiveValue ??
            passwordReader.readPassword(hint: "Enter certificates repo decryption password:")

        let taskConfig = CertsUpdateConfig(
            common: CertsCommonConfig(
                repoURL: commandConfig.repoURL,
                clonedRepoDir: options.clonedRepoDir,
                repoBranch: commandConfig.repoBranch,
                encryptionPassword: repoPassword
            ),
            bundleIDs: bundleId,
            profileTypes: type
        )

        let task = try TasksFactory.makeCertsUpdateTask(
            authKeyPath: authKeyPath,
            authKeyIssuerID: authKeyIssuerID,
            taskConfig: taskConfig
        )

        _ = try task.run()
    }
}
