//

import Foundation
import SwiftlaneCore

public protocol CertsInstalling {
    func installCertificatesAndProfiles(config: CertsInstallConfig) throws
        -> [(MobileProvision, installPath: AbsolutePath)]
}

public class CertsInstaller: CertsInstalling {
    private let logger: Logging

    private let repo: CertsRepositoryProtocol
    private let atomicInstaller: CertsAtomicInstalling
    private let filesManager: FSManaging
    private let remoteCertInstaller: RemoteCertificateInstalling

    public init(
        logger: Logging,
        repo: CertsRepositoryProtocol,
        atomicInstaller: CertsAtomicInstalling,
        filesManager: FSManaging,
        remoteCertInstaller: RemoteCertificateInstalling
    ) {
        self.logger = logger
        self.repo = repo
        self.atomicInstaller = atomicInstaller
        self.filesManager = filesManager
        self.remoteCertInstaller = remoteCertInstaller
    }

    public func installCertificatesAndProfiles(config: CertsInstallConfig) throws
        -> [(MobileProvision, installPath: AbsolutePath)]
    {
        let clonedRepoPath = try config.common.clonedRepoDir.appending(path: "certs-repo_" + Date().full_custom)

        defer {
            /// Preventing unencrypted private keys to be left on disk.
            try! filesManager.delete(clonedRepoPath)
        }

        logger.important("Cloning certs repository...")

        try repo.cloneAndDecryptRepo(
            repoURL: config.common.repoURL,
            repoBranch: config.common.repoBranch,
            encryptionPassword: config.common.encryptionPassword,
            clonedRepoPath: clonedRepoPath
        )

        let installedProfiles = try atomicInstaller.installProvisionProfiles(
            from: clonedRepoPath.appending(path: "profiles")
        )

        let certificateImportTimeout: TimeInterval = 5
        try atomicInstaller.installCertificates(
            from: clonedRepoPath.appending(path: "certs"),
            timeout: certificateImportTimeout,
            reinstall: config.forceReinstall,
            keychainName: config.keychainName,
            keychainPassword: config.keychainPassword
        )

        logger.success("Done installing profiles and certificates.")

        if !config.additionalCertificates.isEmpty {
            logger.important("Installing additional certificates.")

            try config.additionalCertificates.forEach {
                try remoteCertInstaller.installCertificate(
                    from: $0,
                    downloadTimeout: 5,
                    keychainName: config.keychainName,
                    installTimeout: certificateImportTimeout
                )
            }

            logger.success("Done installing additional certificates.")
        }

        return installedProfiles
    }
}
