//

import Combine
import Foundation
import Networking
import SwiftlaneCore

public protocol FirebaseDistributionAPIClientProtocol {
    /// Upload `.ipa` to Firebase Distribution.
    ///
    /// - Parameters:
    ///   - fileName: name of uploaded file in Firebase Distribution.
    ///   - data: contents of an `.ipa` file.
    ///
    /// - Returns: Release name inside FirebaseDistribution.
    func uploadIPA(
        accessToken: FirebaseDistributionDTOs.AccessToken,
        fileName: String,
        data: Data,
        timeout: TimeInterval
    ) -> AnyPublisher<FirebaseDistributionDTOs.UploadReleaseOperation, NetworkingError>

    func getUploadStatus(
        accessToken: FirebaseDistributionDTOs.AccessToken,
        operation: FirebaseDistributionDTOs.UploadReleaseOperation
    ) -> AnyPublisher<FirebaseDistributionDTOs.UploadReleaseStatus, NetworkingError>

    /// Set release notes for a release uploaded beforehand.
    /// - Parameters:
    ///   - releaseName: name of release inside FirebaseDistribution.
    ///   - releaseNotes: release notes text.
    ///
    /// Docs: https://firebase.google.com/docs/reference/app-distribution/rest/v1/projects.apps.releases/patch
    func updateReleaseNotes(
        accessToken: FirebaseDistributionDTOs.AccessToken,
        release: FirebaseDistributionDTOs.Release,
        releaseNotes: String
    ) -> AnyPublisher<FirebaseDistributionDTOs.Release, NetworkingError>

    /// Enables tester access to the specified app release.
    ///
    /// - Parameters:
    ///   - accessToken: access token.
    ///   - release: App release, returned by `getUploadStatus()`.
    ///   - emails: App testers' email addresses.
    ///   - groupsAliases: Firebase tester group aliases.
    func distribute(
        accessToken: FirebaseDistributionDTOs.AccessToken,
        release: FirebaseDistributionDTOs.Release,
        emails: [String],
        groupsAliases: [String]
    ) -> AnyPublisher<Void, NetworkingError>
}
