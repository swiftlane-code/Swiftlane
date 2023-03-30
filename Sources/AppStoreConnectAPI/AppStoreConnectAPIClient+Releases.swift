//

import Bagbutik_AppStore
import Bagbutik_Core
import Bagbutik_Models
import Bagbutik_TestFlight
import Combine
import Foundation
import Networking
import SwiftlaneCore

public extension AppStoreConnectAPIClient {
    func loadAllReleases(for bundleID: String) -> AnyPublisher<[AppStoreConnectAPIDTOs.ReleasedAppStoreVersion], Error> {
        Deferred.erased {
            try await self.loadAllReleases(bundleID: bundleID)
        }
    }
}

private extension AppStoreConnectAPIClient {
    func loadBuildInfo(for appStoreVersion: AppStoreVersionsResponse.Data) async throws
        -> AppStoreConnectAPIDTOs.ReleasedAppStoreVersion
    {
        let versionBuildInfo = try await bagbutikService.request(
            .getBuildForAppStoreVersionV1(id: appStoreVersion.id, fields: [.builds([])])
        )

        let build = try await bagbutikService.request(
            .getBuildV1(
                id: versionBuildInfo.data.id,
                includes: [.preReleaseVersion]
            )
        )

        func versionDump() -> String {
            "\n" + "appStoreVersion: " + String(reflecting: appStoreVersion)
        }

        func buildDump() -> String {
            "\n" + "build: " + String(reflecting: build)
        }

        let versionAttributes = try appStoreVersion.attributes.unwrap(
            errorDescription: "attributes is nil at \(versionDump())"
        )

        let buildAttributes = try build.data.attributes.unwrap(
            errorDescription: "attributes is nil at \(buildDump())"
        )

        let preReleaseVersion = try build.getPreReleaseVersion().unwrap(
            errorDescription: "getPreReleaseVersion() is nil for \(buildDump())"
        )

        let preReleaseVersionAttributes = try preReleaseVersion.attributes.unwrap(
            errorDescription: "getPreReleaseVersion().attributes is nil for \(buildDump())"
        )

        return try AppStoreConnectAPIDTOs.ReleasedAppStoreVersion(
            appStoreState: versionAttributes.appStoreState.unwrap(
                errorDescription: "attributes.appStoreState is nil at \(versionDump())"
            ),
            appStoreVersion: versionAttributes.versionString.unwrap(
                errorDescription: "attributes.versionString is nil at \(versionDump())"
            ),
            buildVersion: preReleaseVersionAttributes.version.unwrap(
                errorDescription: "attributes.version is nil at preReleaseVersionAttributes \(String(reflecting: preReleaseVersionAttributes))"
            ),
            buildNumber: buildAttributes.version.unwrap(
                errorDescription: "attributes.version is nil at \(buildDump())"
            )
        )
    }

    func loadAppID(bundleID: String) async throws -> String {
        let response = try await bagbutikService.request(
            .listAppsV1(
                filters: [.bundleId([bundleID])]
            )
        )
        return try response.data.first.unwrap(
            errorDescription: "App with bundle ID \"\(bundleID)\" not found."
        ).id
    }

    func loadAllReleasedVersions(appID: String) async throws -> [AppStoreVersionsResponse.Data] {
        try await bagbutikService.requestAllPages(
            .listAppStoreVersionsForAppV1(id: appID)
        ).data
    }

    func loadAllReleases(bundleID: String) async throws -> [AppStoreConnectAPIDTOs.ReleasedAppStoreVersion] {
        let appID = try await loadAppID(bundleID: bundleID)

        let allReleases = try await loadAllReleasedVersions(appID: appID)

        return try await allReleases.asyncMap { release in
            try await loadBuildInfo(for: release)
        }
    }
}
