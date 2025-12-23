//

import Foundation
import Git
import Provisioning
import Simulator
import SwiftlaneCore
import Yams

public struct CertsCommandConfig: Codable {
    public static var repoURLEnvKey = ShellEnvKey.CODESIGNING_CERTS_REPO_URL
    public static var repoPasswordEnvKey = ShellEnvKey.CODESIGNING_CERTS_REPO_PASS
    public static var keychainPasswordEnvKey = ShellEnvKey.CI_USER_PASSWORD

    public let repoURL: URL
    public let repoBranch: String
    public let keychainName: String
    public let repoPassword: SensitiveData<String>?
    public let keychainPassword: SensitiveData<String>?

    private enum CodingKeys: String, CodingKey {
        case repoBranch, keychainName
    }

    public init(from decoder: Decoder) throws {
        let envReader = DependencyResolver.shared.resolve(EnvironmentValueReading.self, .shared)
        repoURL = try envReader.url(Self.repoURLEnvKey)
        repoPassword = (try? envReader.string(Self.repoPasswordEnvKey)).map(SensitiveData.init)
        keychainPassword = (try? envReader.string(Self.keychainPasswordEnvKey)).map(SensitiveData.init)

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
        let envReader = DependencyResolver.shared.resolve(EnvironmentValueReading.self, .shared)
        let logger = DependencyResolver.shared.resolve(Logging.self, .shared)

        let isCI = (try? envReader.bool(ShellEnvKey.CI)) != nil

        let repoPassword: String = try {
            if let password = params.options.repoPassword?.sensitiveValue ??
                commandConfig.repoPassword?.sensitiveValue {
                return password
            }
            if !isCI {
                return try passwordReader.readPassword(hint: "Enter certificates repo decryption password:")
            } else {
                struct BadConfiguration: Error {
                    var description: String = "CI mode requires --repo-password option. Interactive password prompt on CI is not allowed."
                }
                throw BadConfiguration()
            }
        }()

        let keychainPassword: String? = try {
            if let password = params.keychainPassword?.sensitiveValue ??
                commandConfig.keychainPassword?.sensitiveValue {
                return password
            }

            if !isCI {
                return try passwordReader.readPassword(hint: "Enter keychain passwod:")
            } else {
                logger.warn("Interactive password prompt on CI is not allowed.")
                return nil
            }
        }()

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
            keychainPassword: keychainPassword,
            authKeyOutputDirectory: params.authKeyOutputDirectory
        )

        let task = TasksFactory.makeCertsInstallTask(
            taskConfig: installConfig
        )

        _ = try task.run()
    }
}
