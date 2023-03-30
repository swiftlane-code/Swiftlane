//

import ArgumentParser
import Foundation
import Git
import Provisioning
import SwiftlaneCore
import Yams

public protocol CertsChangePasswordCommandParamsAccessing {
    var options: CertsCommandOptions { get }

    var commonOptions: CommonOptions { get }
}

public struct CertsChangePasswordCommand: ParsableCommand, CertsChangePasswordCommandParamsAccessing {
    public static var configuration = CommandConfiguration(
        commandName: "changepass",
        abstract: "Reencrypt certificates repo using a new password."
    )

    @OptionGroup public var options: CertsCommandOptions

    @OptionGroup public var commonOptions: CommonOptions

    public init() {}

    public mutating func run() throws {
        Runner().run(self, commandConfigPath: options.config, commonOptions: commonOptions)
    }
}

private class Runner: CommandRunnerProtocol {
    public func run(
        params: CertsChangePasswordCommand,
        commandConfig: CertsCommandConfig,
        sharedConfig _: Void,
        logger: Logging
    ) throws {
        let passwordReader = PasswordReader()

        let repoPassword = try params.options.repoPassword?.sensitiveValue ??
            passwordReader.readPassword(hint: "Enter certificates repo decryption password:")

        let config = CertsChangePasswordTaskConfig(
            common: CertsCommonConfig(
                repoURL: commandConfig.repoURL,
                clonedRepoDir: params.options.clonedRepoDir,
                repoBranch: commandConfig.repoBranch,
                encryptionPassword: repoPassword
            )
        )

        let task = try assembleTask(config: config, logger: logger)

        try task.run()
    }

    private func assembleTask(config: CertsChangePasswordTaskConfig, logger: Logging) throws -> CertsChangePasswordTask {
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

        let certsRepo = CertsRepository(
            git: git,
            openssl: openssl,
            filesManager: filesManager,
            provisioningProfileService: provisioningProfileService,
            provisionProfileParser: provisionProfileParser,
            security: security,
            logger: logger,
            config: CertsRepository.Config(
                gitAuthorName: nil, // use local git config
                gitAuthorEmail: nil // use local git config
            )
        )

        return CertsChangePasswordTask(
            logger: logger,
            shell: shell,
            repo: certsRepo,
            passwordReader: PasswordReader(),
            filesManager: filesManager,
            config: config
        )
    }
}
