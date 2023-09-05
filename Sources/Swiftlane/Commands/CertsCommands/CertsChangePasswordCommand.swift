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
        sharedConfig _: Void
    ) throws {
        let passwordReader = DependencyResolver.shared.resolve(PasswordReading.self, .shared)

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

        let task = try TasksFactory.makeCertsChangePasswordTask(config: config)

        try task.run()
    }
}
