//

import Foundation
import Git
import Provisioning
import Simulator
import SwiftlaneCore
import Yams

public struct CertsCommandConfig: Codable {
    public static var repoURLEnvKey: ShellEnvKeyRepresentable = ShellEnvKey.ADP_ARTIFACTS_REPO

    public let repoURL: URL
    public let repoBranch: String
    public let keychainName: String

    private enum CodingKeys: String, CodingKey {
        case repoBranch, keychainName
    }

    public init(from decoder: Decoder) throws {
        repoURL = try EnvironmentValueReader().url(Self.repoURLEnvKey)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        repoBranch = try container.decode(String.self, forKey: .repoBranch)
        keychainName = try container.decode(String.self, forKey: .keychainName)
    }
}

public class CertsInstallCommandRunner: CommandRunnerProtocol {
    public func run(
        params: CertsInstallCommandParamsAccessing,
        commandConfig: CertsCommandConfig,
        sharedConfig _: Void
    ) throws {
        let additionalCertificates = try params.additionalCertificates.split(separator: ",")
            .map { String($0) }
            .map {
                try URL(string: $0).unwrap(errorDescription: "\($0.quoted) is not a valid URL.")
            }

        let passwordReader = DependencyResolver.shared.resolve(PasswordReading.self, .shared)

        let repoPassword = try params.options.repoPassword?.sensitiveValue ??
            passwordReader.readPassword(hint: "Enter certificates repo decryption password:")

        let keychainPassword = try params.keychainPassword?.sensitiveValue ??
            passwordReader.readPassword(hint: "Enter keychain passwod:")

        let installConfig = CertsInstallConfig(
            common: CertsCommonConfig(
                repoURL: commandConfig.repoURL,
                clonedRepoDir: params.options.clonedRepoDir,
                repoBranch: commandConfig.repoBranch,
                encryptionPassword: repoPassword
            ),
            forceReinstall: params.forceReinstall,
            additionalCertificates: additionalCertificates,
            keychainName: commandConfig.keychainName,
            keychainPassword: keychainPassword
        )

        let task = TasksFactory.makeCertsInstallTask(
            taskConfig: installConfig
        )

        _ = try task.run()
    }
}
