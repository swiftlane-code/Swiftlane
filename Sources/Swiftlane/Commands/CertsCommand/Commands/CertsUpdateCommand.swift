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
        sharedConfig: SharedConfigData,
        logger: Logging
    ) throws {
        let sigIntHandler = SigIntHandler(logger: logger)
        let xcodeChecker = XcodeChecker()

        let filesManager = FSManager(
            logger: logger,
            fileManager: FileManager.default
        )

        let shell = ShellExecutor(
            sigIntHandler: sigIntHandler,
            logger: logger,
            xcodeChecker: xcodeChecker,
            filesManager: filesManager
        )

        let git = Git(
            shell: shell,
            filesManager: filesManager,
            diffParser: GitDiffParser(logger: logger)
        )

        let openssl = OpenSSLService(
            shell: shell,
            filesManager: filesManager
        )

        let provisionProfileParser = MobileProvisionParser(
            logger: logger,
            shell: shell
        )

        let security = MacOSSecurity(shell: shell)

        let provisioningProfileService = ProvisioningProfilesService(
            filesManager: filesManager,
            logger: logger,
            provisionProfileParser: provisionProfileParser
        )

        let authKeyID = try AppStoreConnectAuthKeyIDParser().apiKeyID(from: authKeyPath)

        let passwordReader = PasswordReader()

        let repoPassword = try options.repoPassword?.sensitiveValue ??
            passwordReader.readPassword(hint: "Enter certificates repo decryption password:")

        let installConfig = CertsUpdateConfig(
            common: CertsCommonConfig(
                repoURL: commandConfig.repoURL,
                clonedRepoDir: options.clonedRepoDir,
                repoBranch: commandConfig.repoBranch,
                encryptionPassword: repoPassword
            ),
            bundleIDs: bundleId,
            profileTypes: type
        )

        let appStoreConnectAPIClient = try AppStoreConnectAPIClient(
            keyId: authKeyID,
            issuerId: authKeyIssuerID.sensitiveValue,
            privateKeyPath: authKeyPath.string
        )

        let certsService = CertsUpdater(
            logger: logger,
            repo: CertsRepository(
                git: git,
                openssl: openssl,
                filesManager: filesManager,
                provisioningProfileService: provisioningProfileService,
                provisionProfileParser: provisionProfileParser,
                security: security,
                logger: logger,
                config: CertsRepository.Config(
                    gitAuthorName: sharedConfig.values.gitAuthorName,
                    gitAuthorEmail: sharedConfig.values.gitAuthorEmail
                )
            ),
            generator: CertsGenerator(
                logger: logger,
                openssl: openssl,
                api: appStoreConnectAPIClient
            ),
            filesManager: filesManager
        )

        let task = CertsUpdateTask(
            logger: logger,
            shell: shell,
            certsService: certsService,
            config: installConfig
        )

        _ = try task.run()
    }
}
