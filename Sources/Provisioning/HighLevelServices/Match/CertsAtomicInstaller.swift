//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol CertsAtomicInstalling {
    func installProvisionProfiles(
        from profilesDir: AbsolutePath
    ) throws -> [(MobileProvision, installPath: AbsolutePath)]

    func installCertificates(
        from certificatesDir: AbsolutePath,
        timeout: TimeInterval,
        reinstall: Bool,
        keychainName: String,
        keychainPassword: String
    ) throws
}

public class CertsAtomicInstaller {
    private let logger: Logging
    private let filesManager: FSManaging
    private let openssl: OpenSSLServicing
    private let security: MacOSSecurityProtocol
    private let provisioningProfileService: ProvisioningProfilesServicing

    public init(
        logger: Logging,
        filesManager: FSManaging,
        openssl: OpenSSLServicing,
        security: MacOSSecurityProtocol,
        provisioningProfileService: ProvisioningProfilesServicing
    ) {
        self.logger = logger
        self.filesManager = filesManager
        self.openssl = openssl
        self.security = security
        self.provisioningProfileService = provisioningProfileService
    }
}

// swiftformat:disable indent
extension CertsAtomicInstaller: CertsAtomicInstalling {
	/// Recursively traverses `profilesDir`
	/// and copies all found profiles into `~/Library/MobileDevice/Provisioning Profiles/`.
	///
	///    Valid profile extensions: `".mobileprovision"`.
	///
	/// - Parameter profilesDir: directory where to look (recursively) for profiles.
	public func installProvisionProfiles(
		from profilesDir: AbsolutePath
	) throws -> [(MobileProvision, installPath: AbsolutePath)] {
		let validExtension = [".mobileprovision"]
		let profilesFiles = try filesManager.find(profilesDir)
			.filter { file in
				validExtension.contains { file.hasSuffix($0) }
			}

		logger.important("Going to install \(profilesFiles.count) profiles.")

		if profilesFiles.isEmpty {
			logger.error("No profiles found in \(profilesDir.string.quoted)")
		}

		let installed: [(MobileProvision, installPath: AbsolutePath)] = try profilesFiles
			.map { file in
				let (profile, path) = try provisioningProfileService.installProvisioningProfile(path: file)
				return (profile, path)
			}

		return installed
	}

	/// Certificates are installed via `security` cli tool into keychain.
	public func installCertificates(
	    from certificatesDir: AbsolutePath,
	    timeout: TimeInterval,
	    reinstall: Bool,
	    keychainName: String,
	    keychainPassword: String
	) throws {
		let keychainPath = try security.getKeychainPath(keychainName: keychainName)
		try security.unlockKeychain(keychainPath, password: keychainPassword)

		let allFiles = try filesManager.find(certificatesDir)
		let certificatesFiles = allFiles.filter { $0.hasSuffix(CertificatesConstants.certificateFileExtension) }
		let privateKeysFiles = allFiles.filter { $0.hasSuffix(CertificatesConstants.privateKeyExtension) }

		// swiftformat:disable:next wrap
		logger.important("Going to install \(certificatesFiles.count) certificates and \(privateKeysFiles.count) private keys into \(keychainPath.lastComponent.deletingExtension.string.quoted) keychain.")

		if certificatesFiles.isEmpty {
			logger.error("No certificates found in \(certificatesDir.string.quoted)")
		}

		if privateKeysFiles.isEmpty {
			logger.error("No private keys found in \(certificatesDir.string.quoted)")
		}

		if certificatesFiles.count != privateKeysFiles.count {
			logger.error("Count of certificates and count private keys aren't equal.")
		}

		func uninstall(certificateFile file: AbsolutePath) throws {
			logger.important("Uninstalling \(file.lastComponent.string.quoted)...")
			let fingerprint = try openssl.x509Fingerprint(
			    inFile: file,
			    format: .der,
			    msgDigest: .sha1
			).replacingOccurrences(of: ":", with: "")

			try security.deleteCertificateAndPrivateKey(
			    certificateFingerprint: fingerprint,
			    deleteTrustSettings: true,
			    keychainPath: keychainPath,
			    timeout: timeout
			)
			logger.info("\(file.lastComponent.string.quoted) uninstalled.")
		}

		/// Import item into keychain.
		/// - Parameter file: path to item file.
		/// - Returns: `true` if the item was installed. `false` if the item already exists in the keychain.
		func install(file: AbsolutePath) throws -> Bool {
			logger.important("Installing \(file.lastComponent.string.quoted)...")
			let imported = try security.importItem(
			    item: file,
			    keychainPath: keychainPath,
			    trustedBinaries: [
			        "/usr/bin/codesign",
			        "/usr/bin/productsign",
			        "/usr/bin/productbuild",
			        "/usr/bin/security",
			    ],
			    timeout: timeout
			)

			if imported {
				logger.success("\(file.lastComponent.string.quoted) installed.")
			} else {
				logger.debug("\(file.lastComponent.string.quoted) already exists in the keychain.")
			}

			return imported
		}

		if reinstall {
			try certificatesFiles
				.forEach { file in
					// Uninstall certificate and it's private key.
					try uninstall(certificateFile: file)
				}
		}

		let installedNewCertsOrPrivateKeys =
		try (certificatesFiles + privateKeysFiles)
			.map { file in
				try install(file: file)
			}
			.contains(true)

		let validIdentities = try security.validCodesigningIdentities(keychainPath)

		let expectedFingerprints = try certificatesFiles.map {
			try openssl.x509Fingerprint(
			    inFile: $0,
			    format: .der,
			    msgDigest: .sha1
			).replacingOccurrences(of: ":", with: "")
		}

		let allInstalledAreValid = Set(validIdentities.map(\.fingerprint)).isSuperset(of: Set(expectedFingerprints))

		if allInstalledAreValid {
			logger.success("All installed identities are valid")
		} else {
			logger.warn("Looks like some of the installed identities are not listed as valid by MacOS security tool.")
			logger.warn("Expected valid identities fingerprints:\n\t\(expectedFingerprints.joined(separator: ",\n\t"))")
			logger.warn("Valid identities: \(validIdentities.asPrettyJSON())")
		}

		guard installedNewCertsOrPrivateKeys || !allInstalledAreValid else {
			logger.debug(
				"Nothing new was installed into keychain, " +
				"no need to allow Apple apps to sign things using private keys in keychain..."
			)
			return
		}

		logger.important("Allowing Apple apps to sign things using private keys in keychain...")

		// This can be really time consuming, so we run it only if needed.
		try security.allowSigningUsingKeysFromKeychain(
		    keychainPath,
		    password: keychainPassword
		)
	}
}

// swiftformat:enable indent
