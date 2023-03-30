//

import ArgumentParser
import Foundation
import SwiftlaneCore

public struct CertsCommandOptions: ParsableArguments {
    @Option(help: "Path to certificates repo config.")
    public var config: AbsolutePath = try! .init(
        FileManager.default.currentDirectoryPath
            .appendingPathComponent("certs-config.yml")
    )

    @Option(help: "Where to temporary store cloned certificates repo.")
    public var clonedRepoDir: AbsolutePath

    @Option(help: "Password used to decrypt certificates repo.")
    public var repoPassword: SensitiveData<String>?

    public init() {}
}

public struct CertsCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "certs",
        abstract: "Install certificates and provisioning profiles.",
        subcommands: [
            CertsInstallCommand.self,
            CertsUpdateCommand.self,
            CertsChangePasswordCommand.self,
        ],
        defaultSubcommand: CertsInstallCommand.self
    )

    public init() {}
}
