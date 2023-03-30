//

import AppStoreConnectAPI
import Combine
import Foundation
import Git
import SwiftlaneCore

public struct CertsInstallConfig {
    public let common: CertsCommonConfig
    public let forceReinstall: Bool
    public let additionalCertificates: [URL]
    public let keychainName: String
    public let keychainPassword: String

    public init(
        common: CertsCommonConfig,
        forceReinstall: Bool,
        additionalCertificates: [URL],
        keychainName: String,
        keychainPassword: String
    ) {
        self.common = common
        self.forceReinstall = forceReinstall
        self.additionalCertificates = additionalCertificates
        self.keychainName = keychainName
        self.keychainPassword = keychainPassword
    }
}

public struct CertsCommonConfig {
    public let repoURL: URL
    public let clonedRepoDir: AbsolutePath
    public let repoBranch: String
    public let encryptionPassword: String

    public init(
        repoURL: URL,
        clonedRepoDir: AbsolutePath,
        repoBranch: String,
        encryptionPassword: String
    ) {
        self.repoURL = repoURL
        self.clonedRepoDir = clonedRepoDir
        self.repoBranch = repoBranch
        self.encryptionPassword = encryptionPassword
    }
}

public struct CertsUpdateConfig {
    public let common: CertsCommonConfig
    public let bundleIDs: [String]
    public let profileTypes: [ProvisionProfileType]

    public init(
        common: CertsCommonConfig,
        bundleIDs: [String],
        profileTypes: [ProvisionProfileType]
    ) {
        self.common = common
        self.bundleIDs = bundleIDs
        self.profileTypes = profileTypes
    }
}

// sourcery: AutoMockable
public protocol CertsUpdating {
    func updateCertificatesAndProfiles(
        updateConfig: CertsUpdateConfig
    ) throws
}

public final class CertsUpdater {
    private let logger: Logging
    private let repo: CertsRepositoryProtocol
    private let generator: CertsGenerating
    private let filesManager: FSManaging

    public init(
        logger: Logging,
        repo: CertsRepositoryProtocol,
        generator: CertsGenerating,
        filesManager: FSManaging
    ) {
        self.logger = logger
        self.repo = repo
        self.generator = generator
        self.filesManager = filesManager
    }
}

extension CertsUpdater: CertsUpdating {
    public func createCertificateIfNeeded(
        clonedRepoPath: AbsolutePath,
        certificateType: CodeSigningCertificateType
    ) throws -> String {
        let existingCertificatesIDs = try repo.getCertificateID(
            certificateType: certificateType,
            clonedRepoPath: clonedRepoPath
        )

        let validCertificatesIDs = try existingCertificatesIDs.filter { existingCertID in
            if try generator.verifyCertificate(id: existingCertID) {
                logger.success("Keeping existing valid \(certificateType.rawValue) certificate with id \(existingCertID)")
                return true
            } else {
                try repo.deleteCertificateFiles(
                    clonedRepoPath: clonedRepoPath,
                    certificateType: certificateType,
                    certificateID: existingCertID
                )
                return false
            }
        }

        if validCertificatesIDs.count > 1 {
            logger.warn("Unexpected! More than one valid cert+key pairs of type \(certificateType.rawValue) exist: \(validCertificatesIDs)")
            logger.warn("Going to keep only first pair of them all.")

            try validCertificatesIDs.dropFirst().forEach {
                try repo.deleteCertificateFiles(
                    clonedRepoPath: clonedRepoPath,
                    certificateType: certificateType,
                    certificateID: $0
                )
            }
        }

        if let validCertificateID = validCertificatesIDs.first {
            return validCertificateID
        }

        logger.warn("No valid \(certificateType.rawValue) certificates found.")

        logger.warn("Generating new \(certificateType.rawValue) certificate...")
        let cert = try generator.createCertificate(
            certificateType: certificateType
        )

        try repo.saveCertificate(
            clonedRepoPath: clonedRepoPath,
            certificateType: certificateType,
            cert: cert.cert,
            certID: cert.certID,
            privateKey: cert.privateKey
        )

        logger.success("Generated new \(certificateType.rawValue) certificate with id \(cert.certID)")
        return cert.certID
    }

    public func createProfileIfNeeded(
        clonedRepoPath: AbsolutePath,
        profileType: ProvisionProfileType,
        bundleID: AppStoreConnectAPIDTOs.BundleID,
        certificateID: String
    ) throws {
        if let existingProfile = try repo.getProvisioningProfile(
            clonedRepoPath: clonedRepoPath,
            profileType: profileType,
            bundleID: bundleID.identifier
        ) {
            if try generator.verifyProfile(profile: existingProfile) {
                logger.success("Keeping existing \(profileType.rawValue) profile for \(bundleID.identifier)")
                return
            } else {
                try repo.deleteProfileFile(
                    clonedRepoPath: clonedRepoPath,
                    profileType: profileType,
                    bundleID: bundleID.identifier
                )
            }
        }

        logger.warn("Creating new \(profileType.rawValue) profile for \(bundleID.identifier)...")
        let profileData = try generator.createProvisioningProfile(
            profileName: "Swiftlane \(profileType.rawValue) \(bundleID.identifier)",
            for: bundleID,
            profileType: profileType,
            certificateID: certificateID
        )

        try repo.saveProfile(
            profileData: profileData,
            clonedRepoPath: clonedRepoPath,
            profileType: profileType,
            bundleID: bundleID.identifier
        )

        logger.success("Created new \(profileType.rawValue) profile for \(bundleID.identifier)")
    }

    public func updateCertificatesAndProfiles(
        updateConfig: CertsUpdateConfig
    ) throws {
        let bundleIDs = try generator.verifyBundleIDsExistInAppStoreConnect(
            bundleIDs: updateConfig.bundleIDs
        )

        let clonedRepoPath = try updateConfig.common.clonedRepoDir.appending(path: "certs-repo_" + Date().full_custom)

        defer {
            /// Preventing unencrypted private keys to be left on disk.
            try! filesManager.delete(clonedRepoPath)
        }

        // Probably not needed here but keep in mind that RSA keypair is generated via Keychain API...
        //		let keychainPath = try security.getKeychainPath(keychainName: config.keychainName)
        //		try security.unlockKeychain(keychainPath, password: config.keychainPassword)

        try repo.cloneAndDecryptRepo(
            repoURL: updateConfig.common.repoURL,
            repoBranch: updateConfig.common.repoBranch,
            encryptionPassword: updateConfig.common.encryptionPassword,
            clonedRepoPath: clonedRepoPath
        )

        for profileType in updateConfig.profileTypes {
            let certificateType: CodeSigningCertificateType = {
                switch profileType {
                case .appstore, .adhoc:
                    return .distribution
                case .development:
                    return .development
                }
            }()

            let certificateID = try createCertificateIfNeeded(
                clonedRepoPath: clonedRepoPath,
                certificateType: certificateType
            )

            logger.success("\(certificateType.rawValue) certificate id = \(certificateID)")

            for bundleID in bundleIDs {
                try createProfileIfNeeded(
                    clonedRepoPath: clonedRepoPath,
                    profileType: profileType,
                    bundleID: bundleID,
                    certificateID: certificateID
                )
            }
        }

        try repo.encryptRepoAndCommitChanges(
            clonedRepoPath: clonedRepoPath,
            encryptionPassword: updateConfig.common.encryptionPassword,
            supposeEverythingChanged: false,
            commitMessage: "Update \(updateConfig.profileTypes) certs for \(updateConfig.bundleIDs)"
        )
    }
}
