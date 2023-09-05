//

import Foundation

import AppStoreConnectAPI
import Provisioning
import Simulator
import SwiftlaneCore
import Xcodebuild

public struct CertsChangePasswordTaskConfig {
    public let common: CertsCommonConfig
}

public final class CertsChangePasswordTask {
    public enum Errors: Error {
        case newPasswordMismatch
        case newPasswordIsEmpty
    }

    private let logger: Logging
    private let shell: ShellExecuting
    private let repo: CertsRepositoryProtocol
    private let passwordReader: PasswordReading
    private let filesManager: FSManaging

    private let config: CertsChangePasswordTaskConfig

    public init(
        logger: Logging,
        shell: ShellExecuting,
        repo: CertsRepositoryProtocol,
        passwordReader: PasswordReading,
        filesManager: FSManaging,
        config: CertsChangePasswordTaskConfig
    ) {
        self.logger = logger
        self.shell = shell
        self.repo = repo
        self.passwordReader = passwordReader
        self.filesManager = filesManager
        self.config = config
    }

    public func run() throws {
        // clone repo

        let clonedRepoPath = try config.common.clonedRepoDir.appending(path: "certs-repo_" + Date().full_custom)

        defer {
            try? filesManager.delete(clonedRepoPath)
        }

        try repo.cloneAndDecryptRepo(
            repoURL: config.common.repoURL,
            repoBranch: config.common.repoBranch,
            encryptionPassword: config.common.encryptionPassword,
            clonedRepoPath: clonedRepoPath
        )

        // read new password

        let newRepoPassword = try passwordReader.readPassword(hint: "Enter NEW certificates repo decryption password:")

        guard !newRepoPassword.isEmpty else {
            logger.error("Empty password is not allowed.")
            throw Errors.newPasswordIsEmpty
        }

        guard try newRepoPassword == passwordReader.readPassword(hint: "Repeat NEW password:") else {
            logger.error("New password repeated incorrectly.")
            throw Errors.newPasswordMismatch
        }

        // encrypt with new password

        try repo.encryptRepoAndCommitChanges(
            clonedRepoPath: clonedRepoPath,
            encryptionPassword: newRepoPassword,
            supposeEverythingChanged: true,
            commitMessage: "Changed encryption password"
        )
    }
}
