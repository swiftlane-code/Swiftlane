//

import AppStoreConnectAPI
import Bagbutik_Core
import Bagbutik_Models
import Bagbutik_Provisioning
import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol CertsGenerating {
    func verifyBundleIDsExistInAppStoreConnect(
        bundleIDs: [String]
    ) throws -> [AppStoreConnectAPIDTOs.BundleID]

    func verifyCertificate(id: String) throws -> Bool

    func verifyProfile(profile: MobileProvision) throws -> Bool

    func createCertificate(
        certificateType: CodeSigningCertificateType
    ) throws -> (cert: Data, certID: String, privateKey: SecKey)

    func createProvisioningProfile(
        profileName: String,
        for bundleID: AppStoreConnectAPIDTOs.BundleID,
        profileType: ProvisionProfileType,
        certificateID: String
    ) throws -> Data
}

public class CertsGenerator {
    public enum Errors: Error {
        case someOfBundleIDsDoesntExistInAppStoreConnect(expected: [String], existing: [AppStoreConnectAPIDTOs.BundleID])
    }

    private let api: AppStoreConnectAPIClientProtocol
    private let openssl: OpenSSLServicing
    private let logger: Logging

    public init(
        logger: Logging,
        openssl: OpenSSLServicing,
        api: AppStoreConnectAPIClientProtocol
    ) {
        self.logger = logger
        self.openssl = openssl
        self.api = api
    }

    // NOTE: Only one profile with a specific name can exist in developer portal.
    func removeExistingProfileFromDeveloperPortal(named profileName: String) throws {
        let potentialProfiles = try api.provisioningProfiles(named: profileName).await()

        try potentialProfiles.data.forEach { profile in
            logger.warn("Deleting \(profile.type) profile \(profile.id) \(profile.attributes?.name?.quoted ?? "") from developer portal.")
            try api.deleteProvisionProfile(id: profile.id).await()
        }
    }
}

extension CertsGenerator: CertsGenerating {
    public func verifyBundleIDsExistInAppStoreConnect(
        bundleIDs: [String]
    ) throws -> [AppStoreConnectAPIDTOs.BundleID] {
        let exsistingBundleIDs = try api.bundleIds().await()

        let nonExisting = bundleIDs.filter { requiredBundleID in
            !exsistingBundleIDs.contains { $0.identifier == requiredBundleID }
        }

        guard nonExisting.isEmpty else {
            nonExisting.forEach { bundleID in
                logger.error("Bundle ID \(bundleID.quoted) doesn't exist in AppStoreConnect.")
            }
            logger.error("Existing bundle IDs: \(exsistingBundleIDs.asPrettyJSON())")
            throw Errors.someOfBundleIDsDoesntExistInAppStoreConnect(
                expected: bundleIDs,
                existing: exsistingBundleIDs
            )
        }

        logger.success("All required bundle IDs exist in AppStoreConnect.")

        return exsistingBundleIDs.filter { bundleIDs.contains($0.identifier) }
    }

    public func verifyCertificate(id: String) throws -> Bool {
        logger.important("Verifying certificate with id \(id.quoted)...")

        let certificate: Bagbutik_Models.CertificateResponse

        do {
            certificate = try api.getCertificate(id: id).await()
        } catch Bagbutik_Core.ServiceError.notFound {
            logger.warn("Certificate with id \(id.quoted) not found in developer portal. Most probably it has been revoked.")
            return false
        }

        // VALIDITY: there is no single value representing validity of a certificate.

        // EXPIRATION

        guard let expirationDate = certificate.data.attributes?.expirationDate else {
            logger.error("Certificate response info has no `expirationDate` value.")
            return false
        }

        guard expirationDate > Date() else {
            logger.warn("Certificate expired. Expiration date: \(expirationDate)")
            return false
        }

        // OK

        logger.success("Certificate is valid.")
        return true
    }

    public func verifyProfile(profile: MobileProvision) throws -> Bool {
        logger.important("Verifying profile with name \(profile.Name)")

        // GET PROFILE FROM API

        let potentialProfiles = try api.provisioningProfiles(named: profile.Name).await()

        logger.important("Found \(potentialProfiles.data.count) profile(s) with the same name in developer portal.")

        guard let thisProfile = potentialProfiles.data.first(where: {
            $0.attributes?.uuid == profile.UUID
        }) else {
            logger.error("Profile with uuid \(profile.UUID.quoted) doesn't exist in developer portal.")
            return false
        }

        // NOTE: Delete obsolete profile from developer portal.
        func deleteProfileFromDeveloperPortal() throws {
            logger.warn("Deleting \(thisProfile.type) profile \(thisProfile.id) \(thisProfile.attributes?.name?.quoted ?? "") from developer portal.")
            try api.deleteProvisionProfile(id: thisProfile.id).await()
        }

        logger.verbose(thisProfile.asPrettyJSON())

        // VALIDITY

        switch thisProfile.attributes?.profileState {
        case .active:
            logger.success("Profile state is ACTIVE.")
        case .invalid:
            logger.warn("Profile state is INVALID.")
            try deleteProfileFromDeveloperPortal()
            return false
        case .none:
            logger.error("Profile state is NIL.")
            try deleteProfileFromDeveloperPortal()
            return false
        }

        // EXPIRATION

        let expirationDate = try (thisProfile.attributes?.expirationDate).unwrap(errorDescription: "expirationDate is nil")

        guard expirationDate > Date() else {
            logger.error("Profile \(profile.Name) has expired at \(expirationDate)")
            try deleteProfileFromDeveloperPortal()
            return false
        }

        let fmt = DateComponentsFormatter()
        fmt.allowedUnits = [.day, .month]
        fmt.unitsStyle = .full
        fmt.maximumUnitCount = 2
        let untilExpirationString = fmt.string(from: Date(), to: expirationDate) ?? "\(expirationDate)"

        logger.success("Profile \(profile.Name) expires in \(untilExpirationString)")

        // DEVICES

        let profileType = try (thisProfile.attributes?.profileType).unwrap(
            errorDescription: "Profile's \"attributes\" value is nil."
        )

        switch thisProfile.attributes?.profileType {
        case .iOSAppAdhoc, .iOSAppDevelopment:
            let devicesCount = thisProfile.relationships?.devices?.data?.count
            logger.info("\(devicesCount ?? 0) devices are included in profile \(profile.Name).")

            let activeDevices = try api.activeDevices().await()
            logger.info("\(activeDevices.count) active devices are registered in developer portal.")

            guard devicesCount == activeDevices.count else {
                logger.warn("Need to update the profile to include all devices registered in developer portal.")
                try deleteProfileFromDeveloperPortal()
                return false
            }

        case .iOSAppStore:
            logger.debug("No devices need to be included to an AppStore provisioning profile.")

        default:
            logger.error("Verifying profile of type \(profileType.rawValue.quoted) is not supported.")
            fatalError()
        }

        // OK

        logger.success("Profile \(profile.Name.quoted) is valid.")
        return true
    }

    public func createCertificate(
        certificateType: CodeSigningCertificateType
    ) throws -> (cert: Data, certID: String, privateKey: SecKey) {
        logger.important("Creating \(certificateType.rawValue) certificate...")

        let (privateKey, _) = try KeychainService().createKeyPair(
            privateKeyName: "Swiftlane.CertsService.privateKey",
            publicKeyName: "Swiftlane.CertsService.publicKey",
            privateKeyIsPermanent: false,
            publicKeyIsPermanent: false,
            keyAlgorithm: .RSA,
            keySizeInBits: 2048
        )

        let csr = try openssl.createCSR(
            commonName: "Swiftlane CSR for \(certificateType.rawValue) certificate",
            privateKey: try KeychainService().exportPEMRSAPrivateKey(privateKey),
            digest: .sha256
        )

        logger.debug("CSR: \(csr)")

        let createCertificateResponse = try api.createCertificate(
            csrContent: csr,
            certificateType: {
                switch certificateType {
                case .distribution:
                    return .distribution
                case .development:
                    return .development
                }
            }()
        ).await()

        logger.verbose("Create certificate response: " + createCertificateResponse.asPrettyJSON())

        let certID = createCertificateResponse.data.id

        let certDataBase64 = try createCertificateResponse.data.attributes
            .unwrap(errorDescription: "createCertificate response has nil attributes.")
            .certificateContent
            .unwrap(errorDescription: "createCertificate response has nil certificateContent.")

        let certData = try Data(base64Encoded: certDataBase64).unwrap(
            errorDescription: "Unable to decode base64 certificateContent."
        )

        return (cert: certData, certID: certID, privateKey: privateKey)
    }

    public func createProvisioningProfile(
        profileName: String,
        for bundleID: AppStoreConnectAPIDTOs.BundleID,
        profileType: ProvisionProfileType,
        certificateID: String
    ) throws -> Data {
        logger.important("Creating \(profileName.quoted) profile...")

        let devices: [Bagbutik_Models.Device]

        switch profileType {
        case .appstore:
            devices = []
            logger.debug("No devices need to be associated to an appstore provisioning profile.")
        case .development, .adhoc:
            devices = try api.devices().await()
            logger.debug("Including \(devices.count) devices for \(profileType) provisioning profile.")
        }

        logger.debug("Checking for existing profiles in developer portal with the same name as we are going to create.")
        try removeExistingProfileFromDeveloperPortal(named: profileName)

        let result = try api.createProvisioningProfile(
            name: profileName,
            type: {
                switch profileType {
                case .appstore:
                    return .iOSAppStore
                case .adhoc:
                    return .iOSAppAdhoc
                case .development:
                    return .iOSAppDevelopment
                }
            }(),
            bundleID_ID: bundleID.appStoreConnectID,
            certificatesIDs: [certificateID],
            devicesIDs: devices.map(\.id)
        ).await()

        logger.verbose("profile content: \(result)")

        return result
    }
}
