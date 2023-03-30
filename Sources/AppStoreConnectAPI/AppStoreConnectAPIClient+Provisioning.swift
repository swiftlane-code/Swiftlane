//

import Bagbutik_Core
import Bagbutik_Models
import Bagbutik_Provisioning
import Combine
import Foundation
import Networking
import SwiftlaneCore

public extension AppStoreConnectAPIClient {
    func createCertificate(
        csrContent: String,
        certificateType: CertificateType
    ) -> AnyPublisher<CertificateResponse, Error> {
        Deferred.erased { () -> CertificateResponse in
            let request = CertificateCreateRequest(
                data: CertificateCreateRequest.Data(
                    attributes: CertificateCreateRequest.Data.Attributes(
                        certificateType: certificateType,
                        csrContent: csrContent
                    )
                )
            )
            let response = try await self.bagbutikService.request(.createCertificateV1(requestBody: request))

            return response
        }
    }

    func createProvisioningProfile(
        name: String,
        type: Profile.Attributes.ProfileType,
        bundleID_ID: String,
        certificatesIDs: [String],
        devicesIDs: [String]
    ) -> AnyPublisher<Data, Error> {
        Deferred.erased { () -> Data in
            let request = ProfileCreateRequest(
                data: ProfileCreateRequest.Data(
                    attributes: ProfileCreateRequest.Data.Attributes(
                        name: name,
                        profileType: type
                    ),
                    relationships: ProfileCreateRequest.Data.Relationships(
                        bundleId: ProfileCreateRequest.Data.Relationships.BundleId(
                            data: ProfileCreateRequest.Data.Relationships.BundleId.Data(
                                id: bundleID_ID
                            )
                        ),
                        certificates: ProfileCreateRequest.Data.Relationships.Certificates(
                            data: certificatesIDs.map { .init(id: $0) }
                        ),
                        devices: ProfileCreateRequest.Data.Relationships.Devices(
                            data: devicesIDs.map { .init(id: $0) }
                        )
                    )
                )
            )
            let response = try await self.bagbutikService.request(.createProfileV1(requestBody: request))

            let profileData = response.data.attributes?.profileContent.flatMap { Data(base64Encoded: $0) }
            return try profileData.unwrap()
        }
    }

    func bundleIds() -> AnyPublisher<[AppStoreConnectAPIDTOs.BundleID], Error> {
        Deferred {
            try await self.bagbutikService.request(
                .listBundleIdsV1(
                    fields: [.bundleIds([.identifier, .name])],
                    filters: [.platform([.iOS])],
                    includes: [],
                    sorts: [.seedIdDescending, .idDescending]
                )
            )
        }
        .tryMap {
            try $0.data.map {
                AppStoreConnectAPIDTOs.BundleID(
                    name: try ($0.attributes?.name).unwrap(),
                    identifier: try ($0.attributes?.identifier).unwrap(),
                    appStoreConnectID: $0.id
                )
            }
        }
        .eraseToAnyPublisher()
    }

    func devices() -> AnyPublisher<[Device], Error> {
        Deferred.erased {
            try await self.bagbutikService.request(
                .listDevicesV1(
                    fields: [.devices([.name, .status, .addedDate, .deviceClass, .model, .platform, .udid])],
                    filters: [.platform([.iOS])],
                    sorts: nil,
                    limit: 200
                )
            ).data
        }
    }

    func activeDevices() -> AnyPublisher<[Device], Error> {
        devices()
            .tryMap {
                try $0.filter {
                    try $0.attributes.unwrap(
                        errorDescription: "Device.status is nil"
                    ).status == .enabled
                }
            }
            .eraseToAnyPublisher()
    }

    func getCertificate(id: String) -> AnyPublisher<CertificateResponse, Error> {
        Deferred.erased {
            try await self.bagbutikService.request(
                .getCertificateV1(
                    id: id,
                    fields: [
                        .certificates([
                            .certificateType,
                            .displayName,
                            .expirationDate,
                            .platform,
                            .serialNumber,
                            .name,
                        ]),
                    ]
                )
            )
        }
    }

    func provisioningProfiles(named name: String) -> AnyPublisher<ProfilesResponse, Error> {
        Deferred.erased {
            try await self.bagbutikService.request(
                .listProfilesV1(
                    fields: [.profiles(ListProfilesV1.Field.Profiles.allCases)],
                    filters: [ListProfilesV1.Filter.name([name])],
                    includes: [
                        .devices,
                        .certificates,
                        .bundleId,
                    ],
                    sorts: nil,
                    limits: nil
                )
            )
        }
    }

    func getProvisionProfile(id: String) -> AnyPublisher<ProfileResponse, Error> {
        Deferred.erased {
            try await self.bagbutikService.request(
                .getProfileV1(
                    id: id,
                    fields: [
                        .profiles([
                            .expirationDate,
                            .platform,
                            .profileType,
                            .name,
                            .bundleId,
                            .certificates,
                            .createdDate,
                            .profileState,
                            .uuid,
                            .devices,
                        ]),
                    ], includes: [
                        .devices,
                        .certificates,
                        .bundleId,
                    ], limits: [
                    ]
                )
            )
        }
    }

    func deleteProvisionProfile(id: String) -> AnyPublisher<Void, Error> {
        Deferred {
            try await self.bagbutikService.request(
                .deleteProfileV1(
                    id: id
                )
            )
        }
        .map { _ in () }
        .eraseToAnyPublisher()
    }
}
