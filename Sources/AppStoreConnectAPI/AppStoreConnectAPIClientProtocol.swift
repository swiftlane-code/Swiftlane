//

import Bagbutik_Core
import Bagbutik_Models
import Combine
import Foundation
import Networking

public protocol AppStoreConnectAPIClientProtocol {
    // MARK: - Provisioning

    func createCertificate(
        csrContent: String,
        certificateType: CertificateType
    ) -> AnyPublisher<CertificateResponse, Error>

    func createProvisioningProfile(
        name: String,
        type: Profile.Attributes.ProfileType,
        bundleID_ID: String,
        certificatesIDs: [String],
        devicesIDs: [String]
    ) -> AnyPublisher<Data, Error>

    func bundleIds() -> AnyPublisher<[AppStoreConnectAPIDTOs.BundleID], Error>

    func devices() -> AnyPublisher<[Device], Error>
    func activeDevices() -> AnyPublisher<[Device], Error>

    func getCertificate(id: String) -> AnyPublisher<CertificateResponse, Error>

    func provisioningProfiles(named: String) -> AnyPublisher<ProfilesResponse, Error>
    func getProvisionProfile(id: String) -> AnyPublisher<ProfileResponse, Error>
    func deleteProvisionProfile(id: String) -> AnyPublisher<Void, Error>

    // MARK: - Releases

    func loadAllReleases(for bundleID: String) -> AnyPublisher<[AppStoreConnectAPIDTOs.ReleasedAppStoreVersion], Error>
}

#if DEBUG
    // We cannot generate is using SwiftyMocky because there are type naming conflicts between SwifyMocky and Bagbutik.
    public final class AppStoreConnectAPIClientProtocolMock: AppStoreConnectAPIClientProtocol {
        public init() {}

        var given_createCertificate: (
            (
                _ csrContent: String,
                _ certificateType: CertificateType
            ) -> AnyPublisher<CertificateResponse, Error>
        )?

        var given_createProvisioningProfile: (
            (
                _ name: String,
                _ type: Profile.Attributes.ProfileType,
                _ bundleID_ID: String,
                _ certificatesIDs: [String],
                _ devicesIDs: [String]
            ) -> AnyPublisher<Data, Error>
        )?

        var given_bundleIds: (
            () -> AnyPublisher<[AppStoreConnectAPIDTOs.BundleID], Error>
        )?

        var given_devices: (
            () -> AnyPublisher<[Device], Error>
        )?

        var given_activeDevices: (
            () -> AnyPublisher<[Device], Error>
        )?

        var given_getCertificate: (
            (
                _ id: String
            ) -> AnyPublisher<CertificateResponse, Error>
        )?

        var given_provisioningProfiles: (
            (
                _ named: String
            ) -> AnyPublisher<ProfilesResponse, Error>
        )?

        var given_getProvisionProfile: (
            (
                _ id: String
            ) -> AnyPublisher<ProfileResponse, Error>
        )?

        var given_deleteProvisionProfile: (
            (
                _ id: String
            ) -> AnyPublisher<Void, Error>
        )?

        var given_loadAllReleases: (
            (
                _ bundleID: String
            ) -> AnyPublisher<[AppStoreConnectAPIDTOs.ReleasedAppStoreVersion], Error>
        )?

        // MARK: funcs

        public func createCertificate(
            csrContent: String,
            certificateType: CertificateType
        ) -> AnyPublisher<CertificateResponse, Error> {
            given_createCertificate!(csrContent, certificateType)
        }

        public func createProvisioningProfile(
            name: String,
            type: Profile.Attributes.ProfileType,
            bundleID_ID: String,
            certificatesIDs: [String],
            devicesIDs: [String]
        ) -> AnyPublisher<Data, Error> {
            given_createProvisioningProfile!(name, type, bundleID_ID, certificatesIDs, devicesIDs)
        }

        public func bundleIds() -> AnyPublisher<[AppStoreConnectAPIDTOs.BundleID], Error> {
            given_bundleIds!()
        }

        public func devices() -> AnyPublisher<[Device], Error> {
            given_devices!()
        }

        public func activeDevices() -> AnyPublisher<[Device], Error> {
            given_activeDevices!()
        }

        public func getCertificate(id: String) -> AnyPublisher<CertificateResponse, Error> {
            given_getCertificate!(id)
        }

        public func provisioningProfiles(named: String) -> AnyPublisher<ProfilesResponse, Error> {
            given_provisioningProfiles!(named)
        }

        public func getProvisionProfile(id: String) -> AnyPublisher<ProfileResponse, Error> {
            given_getProvisionProfile!(id)
        }

        public func deleteProvisionProfile(id: String) -> AnyPublisher<Void, Error> {
            given_deleteProvisionProfile!(id)
        }

        public func loadAllReleases(for bundleID: String)
            -> AnyPublisher<[AppStoreConnectAPIDTOs.ReleasedAppStoreVersion], Error>
        {
            given_loadAllReleases!(bundleID)
        }
    }
#endif
