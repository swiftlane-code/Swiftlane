//

import Combine
import Foundation
import Networking
import SwiftlaneCore

extension FirebaseDistributionAPIClient: FirebaseDistributionAPIClientProtocol {
    /// Upload `.ipa` to Firebase Distribution.
    ///
    /// - Parameters:
    ///   - accessToken: see `GoogleAuthAPIClient`.
    ///   - fileName: name of uploaded file in Firebase Distribution.
    ///   - data: contents of an `.ipa` file.
    ///
    /// - Returns: Release name inside FirebaseDistribution.
    public func uploadIPA(
        accessToken: FirebaseDistributionDTOs.AccessToken,
        fileName: String,
        data: Data,
        timeout: TimeInterval
    ) -> AnyPublisher<FirebaseDistributionDTOs.UploadReleaseOperation, NetworkingError> {
        distributionClient
            .post("/upload/v1/projects/\(firebaseProjectID)/apps/\(firebaseAppID)/releases:upload")
            .with(headers: [
                "X-Goog-Upload-File-Name": fileName,
                "X-Goog-Upload-Protocol": "raw",
                "Content-Type": "application/octet-stream",
                "X-Client-Version": "fastlane/0.3.1", // from fastlane plugin
                "authorization": "Bearer " + accessToken.accessToken,
            ])
            .with(body: data)
            .with(timeout: timeout)
            .perform()
            .eraseToAnyPublisher()
    }

    /// Get processing status of uploaded binary.
    ///
    /// - Parameters:
    ///   - accessToken: see `GoogleAuthAPIClient`.
    ///   - operation: Firebase upload operation id.
    public func getUploadStatus(
        accessToken: FirebaseDistributionDTOs.AccessToken,
        operation: FirebaseDistributionDTOs.UploadReleaseOperation
    ) -> AnyPublisher<FirebaseDistributionDTOs.UploadReleaseStatus, NetworkingError> {
        distributionClient
            .get("/v1/".appendingPathComponent(operation.name))
            .with(headers: [
                "authorization": "Bearer " + accessToken.accessToken,
            ])
            .perform()
    }

    /// Set release notes for a release uploaded beforehand.
    /// - Parameters:
    ///   - releaseName: name of release inside FirebaseDistribution.
    ///   - releaseNotes: release notes text.
    ///   - accessToken: see `GoogleAuthAPIClient`.
    ///   - release: Firebase release DTO.
    ///
    /// Docs: https://firebase.google.com/docs/reference/app-distribution/rest/v1/projects.apps.releases/patch
    public func updateReleaseNotes(
        accessToken: FirebaseDistributionDTOs.AccessToken,
        release: FirebaseDistributionDTOs.Release,
        releaseNotes: String
    ) -> AnyPublisher<FirebaseDistributionDTOs.Release, NetworkingError> {
        distributionClient
            .patch("/v1/".appendingPathComponent(release.name) + "?updateMask=release_notes.text")
            .with(headers: [
                "Content-Type": "application/json",
                "authorization": "Bearer " + accessToken.accessToken,
            ])
            .with(body: [
                "name": release.name.eraseToAnyEncodable(),
                "releaseNotes": [
                    "text": releaseNotes,
                ].eraseToAnyEncodable(),
            ])
            .perform()
    }

    /// Enables tester access to the specified app release.
    ///
    /// - Parameters:
    ///   - accessToken: see `GoogleAuthAPIClient`.
    ///   - release: App release, returned by `getUploadStatus()`.
    ///   - emails: App testers' email addresses.
    ///   - groupsAliases: Firebase tester group aliases.
    public func distribute(
        accessToken: FirebaseDistributionDTOs.AccessToken,
        release: FirebaseDistributionDTOs.Release,
        emails: [String],
        groupsAliases: [String]
    ) -> AnyPublisher<Void, NetworkingError> {
        distributionClient
            .post("/v1/".appendingPathComponent(release.name) + ":distribute")
            .with(headers: [
                "Content-Type": "application/json",
                "authorization": "Bearer " + accessToken.accessToken,
            ])
            .with(body: [
                "testerEmails": emails.eraseToAnyEncodable(),
                "groupAliases": groupsAliases.eraseToAnyEncodable(),
            ])
            .perform()
    }
}
