//

import ArgumentParser
import Foundation
import Git
import Provisioning
import SwiftlaneCore
import Yams

public protocol CertsImportCommandParamsAccessing {
    var options: CertsCommandOptions { get }

    var commonOptions: CommonOptions { get }
}

public struct CertsImportCommand: ParsableCommand, CertsImportCommandParamsAccessing {
    public static var configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Manually add new certificates to the repo."
    )

    @OptionGroup public var options: CertsCommandOptions

    @OptionGroup public var commonOptions: CommonOptions

    @Flag(help: "Force import of certificates, even if they already exist.")
    public var force: Bool = false

    @Argument(help: "Path to the certificate to add to the repo.")
    public var certsToImport: [Path]

    public init() {}

    public mutating func run() throws {
        Runner().run(self, commandConfigPath: options.config, commonOptions: commonOptions)
    }
}

private class Runner: CommandRunnerProtocol {
    public func run(
        params: CertsImportCommand,
        commandConfig: CertsCommandConfig,
        sharedConfig _: Void
    ) throws {
        let passwordReader = DependencyResolver.shared.resolve(PasswordReading.self, .shared)

        let repoPassword = try params.options.repoPassword?.sensitiveValue ??
            commandConfig.repoPassword?.sensitiveValue ??
            passwordReader.readPassword(hint: "Enter certificates repo decryption password:")

        let config = CertsImportTaskConfig(
            common: CertsCommonConfig(
                repoURL: commandConfig.repoURL,
                clonedRepoDir: params.options.clonedRepoDir,
                repoBranch: commandConfig.repoBranch,
                encryptionPassword: repoPassword
            ),
            certsToImport: params.certsToImport,
            allowOverwrite: params.force
        )

        let task = try TasksFactory.makeCertsImportTask(config: config)

        try task.run()
    }
}
