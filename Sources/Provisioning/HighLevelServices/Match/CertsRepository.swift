//

import Foundation
import Git
import SwiftlaneCore

// sourcery: AutoMockable
public protocol CertsRepositoryProtocol {
    func markFileAsChanged(
        clonedRepoPath: AbsolutePath,
        filePath: RelativePath
    )

    func encryptRepoAndCommitChanges(
        clonedRepoPath: AbsolutePath,
        encryptionPassword: String,
        supposeEverythingChanged: Bool,
        commitMessage: String?
    ) throws

    func cloneAndDecryptRepo(
        repoURL: URL,
        repoBranch: String,
        encryptionPassword: String,
        clonedRepoPath: AbsolutePath
    ) throws

    func getProvisioningProfile(
        clonedRepoPath: AbsolutePath,
        profileType: ProvisionProfileType,
        bundleID: String
    ) throws -> MobileProvision?

    func getCertificateID(
        certificateType: CodeSigningCertificateType,
        clonedRepoPath: AbsolutePath
    ) throws -> [String]

    func deleteCertificateFiles(
        clonedRepoPath: AbsolutePath,
        certificateType: CodeSigningCertificateType,
        certificateID: String
    ) throws

    func deleteProfileFile(
        clonedRepoPath: AbsolutePath,
        profileType: ProvisionProfileType,
        bundleID: String
    ) throws

    func saveCertificate(
        clonedRepoPath: AbsolutePath,
        certificateType: CodeSigningCertificateType,
        cert: Data,
        certID: String,
        privateKey: SecKey
    ) throws

    func saveProfile(
        profileData: Data,
        clonedRepoPath: AbsolutePath,
        profileType: ProvisionProfileType,
        bundleID: String
    ) throws
}

public extension CertsRepository {
    struct Config {
        let gitAuthorName: String?
        let gitAuthorEmail: String?

        public init(
            gitAuthorName: String?,
            gitAuthorEmail: String?
        ) {
            self.gitAuthorName = gitAuthorName
            self.gitAuthorEmail = gitAuthorEmail
        }
    }
}

public class CertsRepository {
    private let git: GitProtocol
    private let openssl: OpenSSLServicing
    private let filesManager: FSManaging
    private let provisioningProfileService: ProvisioningProfilesServicing
    private let provisionProfileParser: MobileProvisionParsing
    private let security: MacOSSecurityProtocol

    private let logger: Logging

    private let config: Config
    private var changedFiles: [AbsolutePath: [AbsolutePath]] = [:]

    public init(
        git: GitProtocol,
        openssl: OpenSSLServicing,
        filesManager: FSManaging,
        provisioningProfileService: ProvisioningProfilesServicing,
        provisionProfileParser: MobileProvisionParsing,
        security: MacOSSecurityProtocol,
        logger: Logging,
        config: Config
    ) {
        self.git = git
        self.openssl = openssl
        self.filesManager = filesManager
        self.provisioningProfileService = provisioningProfileService
        self.provisionProfileParser = provisionProfileParser
        self.security = security
        self.logger = logger
        self.config = config
    }

    private func certificatesPath(
        clonedRepoPath: AbsolutePath,
        certificateType: CodeSigningCertificateType? = nil
    ) throws -> AbsolutePath {
        let certsDir = try clonedRepoPath.appending(path: "certs")
        guard let certificateTypeDirName = certificateType?.rawValue else {
            return certsDir
        }
        return try certsDir.appending(path: certificateTypeDirName)
    }

    private func profilePath(
        clonedRepoPath: AbsolutePath,
        profileType: ProvisionProfileType,
        bundleID: String
    ) throws -> AbsolutePath {
        let namePrefix: String = {
            switch profileType {
            case .appstore:
                return "AppStore"
            case .adhoc:
                return "AdHoc"
            case .development:
                return "Development"
            }
        }()

        let fileName = namePrefix + "_" + bundleID + ".mobileprovision"

        let filePath = try clonedRepoPath
            .appending(path: "profiles")
            .appending(path: profileType.rawValue)
            .appending(path: fileName)

        return filePath
    }
}

extension CertsRepository: CertsRepositoryProtocol {
    public func markFileAsChanged(
        clonedRepoPath: AbsolutePath,
        filePath: RelativePath
    ) {
        changedFiles[clonedRepoPath, default: []]
            .append(clonedRepoPath.appending(path: filePath))
    }

    public func encryptRepoAndCommitChanges(
        clonedRepoPath: AbsolutePath,
        encryptionPassword: String,
        supposeEverythingChanged: Bool,
        commitMessage: String?
    ) throws {
        let gitignorePath = try clonedRepoPath.appending(path: ".gitignore")
        if !filesManager.fileExists(gitignorePath) {
            try filesManager.write(gitignorePath, text: ".DS_Store\n")
            changedFiles[clonedRepoPath, default: []].append(gitignorePath)
        }

        // encrypt
        let certsPath = try clonedRepoPath.appending(path: "certs")
        let profilesPath = try clonedRepoPath.appending(path: "profiles")

        let certs = try filesManager.directoryExists(certsPath) ? filesManager.find(certsPath) : []
        let profiles = try filesManager.directoryExists(profilesPath) ? filesManager.find(profilesPath) : []

        try (certs + profiles)
            .filter { filesManager.fileExists($0) } // skip directories
            .filter { $0.lastComponent.string != "placeholder" }
            .forEach { file in
                logger.debug("Encrypting file \(file.string.quoted)")

                try openssl.encrypt(
                    inFile: file,
                    outFile: file,
                    cipher: .aes_256_cbc,
                    password: encryptionPassword,
                    base64: true,
                    msgDigest: .pbkdf2
                )

                if supposeEverythingChanged {
                    self.changedFiles[clonedRepoPath, default: []].append(file)
                }
            }

        // check if there is something to commit
        let changedFiles = changedFiles[clonedRepoPath, default: []]

        guard !changedFiles.isEmpty else {
            logger.success("No files have been changed so nothing to commit to git repo.")
            return
        }

        // commit
        try changedFiles.forEach {
            try git.add(repo: clonedRepoPath, $0.string, force: false, ignoreRemoved: false)
        }
        try git.commit(
            repo: clonedRepoPath,
            message: "[swiftlane] " + (commitMessage ?? "changed something"),
            userName: config.gitAuthorName,
            userEmail: config.gitAuthorEmail
        )

        // push
        let remoteName = try git.remotes(repo: clonedRepoPath).first.unwrap()
        try git.push(
            repo: clonedRepoPath,
            refspec: remoteName + " HEAD",
            options: [.setUpstream]
        )

        self.changedFiles[clonedRepoPath] = nil
    }

    /// Download and decrpyt repository with certs.
    /// - Parameters:
    ///   - config: config.
    ///   - downloadedRepoPath: full path where cloned repo will be stored including its name.
    public func cloneAndDecryptRepo(
        repoURL: URL,
        repoBranch: String,
        encryptionPassword: String,
        clonedRepoPath: AbsolutePath
    ) throws {
        try git.cloneRepo(
            url: repoURL,
            to: clonedRepoPath,
            from: nil,
            shallow: false
        )

        let remoteName = try git.remotes(repo: clonedRepoPath).first.unwrap()
        let branchExists = try git.remoteBranchExists(repo: clonedRepoPath, branch: repoBranch, remote: remoteName)

        if branchExists {
            try git.checkout(
                repo: clonedRepoPath,
                ref: repoBranch,
                discardLocalChanges: true
            )
        } else {
            try git.createEmptyBranch(
                repo: clonedRepoPath,
                branch: repoBranch
            )
            try git.reset(
                repo: clonedRepoPath,
                .hard,
                to: nil
            )
        }

        // decrypt
        let certsPath = try clonedRepoPath.appending(path: "certs")
        let profilesPath = try clonedRepoPath.appending(path: "profiles")

        let certs = try filesManager.directoryExists(certsPath) ? filesManager.find(certsPath) : []
        let profiles = try filesManager.directoryExists(profilesPath) ? filesManager.find(profilesPath) : []

        try (certs + profiles)
            .filter { filesManager.fileExists($0) }
            .filter { $0.lastComponent.string != "placeholder" }
            .forEach { file in
                logger.debug("Decrypting file \(file.string.quoted)")

                try openssl.decrypt(
                    inFile: file,
                    outFile: file,
                    cipher: .aes_256_cbc,
                    password: encryptionPassword,
                    base64: true,
                    msgDigest: .pbkdf2
                )
            }

        changedFiles[clonedRepoPath] = []
    }

    public func getProvisioningProfile(
        clonedRepoPath: AbsolutePath,
        profileType: ProvisionProfileType,
        bundleID: String
    ) throws -> MobileProvision? {
        let filePath = try profilePath(
            clonedRepoPath: clonedRepoPath,
            profileType: profileType,
            bundleID: bundleID
        )

        if filesManager.fileExists(filePath) {
            return try provisionProfileParser.parse(provisionPath: filePath)
        }

        return nil
    }

    public func deleteProfileFile(
        clonedRepoPath: AbsolutePath,
        profileType: ProvisionProfileType,
        bundleID: String
    ) throws {
        logger.warn("Deleting \(profileType.rawValue) profile for bundle id \(bundleID)")

        let filePath = try profilePath(
            clonedRepoPath: clonedRepoPath,
            profileType: profileType,
            bundleID: bundleID
        )

        try filesManager.delete(filePath)

        changedFiles[clonedRepoPath, default: []].append(filePath)
    }

    public func deleteCertificateFiles(
        clonedRepoPath: AbsolutePath,
        certificateType: CodeSigningCertificateType,
        certificateID: String
    ) throws {
        logger.warn("Deleting \(certificateType.rawValue) certificate with id \(certificateID)")

        let certsDir = try certificatesPath(
            clonedRepoPath: clonedRepoPath,
            certificateType: certificateType
        )

        try filesManager.ls(certsDir)
            .filter {
                $0.lastComponent.deletingExtension.string == certificateID
            }
            .forEach {
                try filesManager.delete($0)
                changedFiles[clonedRepoPath, default: []].append($0)
            }
    }

    /// - Returns: ID of certificate.
    public func getCertificateID(
        certificateType: CodeSigningCertificateType,
        clonedRepoPath: AbsolutePath
    ) throws -> [String] {
        let certsDir = try certificatesPath(
            clonedRepoPath: clonedRepoPath,
            certificateType: certificateType
        )

        let allFiles = (try? filesManager.find(certsDir)) ?? []
        let certificatesFiles = allFiles.filter { file in
            CertificatesConstants.certificateFileExtensions.contains(file.pathExtension)
        }
        let privateKeysFiles = allFiles.filter { file in
            CertificatesConstants.privateKeyExtensions.contains(file.pathExtension)
        }

        logger.debug("Found \(certificatesFiles.count) certificates and \(privateKeysFiles.count) private keys...")

        if certificatesFiles.isEmpty {
            logger.error("No certificates found in \(certsDir.string.quoted)")
        }

        if privateKeysFiles.isEmpty {
            logger.error("No private keys found in \(certsDir.string.quoted)")
        }

        if certificatesFiles.count != privateKeysFiles.count {
            logger.error("Count of certificates and count private keys aren't equal.")
        }

        if certificatesFiles.isEmpty || privateKeysFiles.isEmpty {
            // generate new certificate
            logger.warn("No certificates or keys found, creating new ones...")

            return []
        }

        // Filter only cert+key pairs.
        // todo: REFACTOR THIS
        let certsWithPrivateKeysIDs = certificatesFiles.filter {
            let privateKeyPath = $0.replacingExtension(with: "")
            return privateKeysFiles.contains(privateKeyPath)
        }.map(\.lastComponent.deletingExtension.string)

        // Delete non paired keys and certs.
        (certificatesFiles + privateKeysFiles)
            .filter { file in
                !certsWithPrivateKeysIDs.contains { id in
                    file.lastComponent.deletingExtension.string == id
                }
            }.forEach {
                logger.warn("\($0) has no its cert/key counterpart.")
//                try filesManager.delete($0)
//                changedFiles[clonedRepoPath, default: []].append($0)
            }

        return certsWithPrivateKeysIDs
    }

    public func saveCertificate(
        clonedRepoPath: AbsolutePath,
        certificateType: CodeSigningCertificateType,
        cert: Data,
        certID: String,
        privateKey: SecKey
    ) throws {
        let certsDir = try certificatesPath(
            clonedRepoPath: clonedRepoPath,
            certificateType: certificateType
        )

        let certPath = try certsDir.appending(path: certID + "." + CertificatesConstants.certificateFileExtensions[0])
        let privateKeyPath = try certsDir.appending(path: certID + "." + CertificatesConstants.privateKeyExtensions[0])

        try filesManager.write(certPath, data: cert)
        changedFiles[clonedRepoPath, default: []].append(certPath)

        let pemPrivateKey = try KeychainService().exportPEMRSAPrivateKey(privateKey)
        try filesManager.write(privateKeyPath, text: pemPrivateKey)
        changedFiles[clonedRepoPath, default: []].append(privateKeyPath)
    }

    public func saveProfile(
        profileData: Data,
        clonedRepoPath: AbsolutePath,
        profileType: ProvisionProfileType,
        bundleID: String
    ) throws {
        let filePath = try profilePath(
            clonedRepoPath: clonedRepoPath,
            profileType: profileType,
            bundleID: bundleID
        )

        try filesManager.write(filePath, data: profileData)
        changedFiles[clonedRepoPath, default: []].append(filePath)
    }
}
