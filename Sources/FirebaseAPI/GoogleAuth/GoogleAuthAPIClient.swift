//

import Combine
import Foundation
import Networking
import SwiftlaneCore

public protocol GoogleAuthAPIClientProtocol {
    /// Get actual **access token** which can be used to authorize a request to Firebase API.
    ///
    /// Note: **access token** is expirable while **refresh token** is NOT expirable.
    ///
    /// Implementation from https://github.com/googleapis/signet
    ///
    /// - Parameter refreshToken: refresh token used to get temporary access token.
    func getAccessToken() -> AnyPublisher<FirebaseDistributionDTOs.AccessToken, NetworkingError>
}

/// Client used to get **access token** from Google's OAuth2.
public final class GoogleAuthAPIClient {
    let client: NetworkingClientProtocol

    /// Can be obtained using Firebase CLI tools, see: https://firebase.google.com/docs/cli#cli-ci-systems
    private let refreshToken: String

    /// - Parameters:
    ///   - client: https://oauth2.googleapis.com networking client.
    ///   - refreshToken: Can be obtained using Firebase CLI tools, see: https://firebase.google.com/docs/cli#cli-ci-systems
    public init(client: NetworkingClient, refreshToken: String) {
        self.client = client
        self.refreshToken = refreshToken
    }
}

public extension GoogleAuthAPIClient {
    /// - Parameter refreshToken: Can be obtained using Firebase CLI tools, see: https://firebase.google.com/docs/cli#cli-ci-systems
    convenience init(refreshToken: String, logger: Logging, logLevel: LoggingLevel = .silent) {
        let client = NetworkingClient(
            baseURL: URL(string: "https://oauth2.googleapis.com")!,
            configuration: .ephemeral,
            logger: NetworkingLogger(
                logLevel: logLevel,
                logger: logger
            )
        )

        self.init(client: client, refreshToken: refreshToken)
    }
}

extension GoogleAuthAPIClient: GoogleAuthAPIClientProtocol {
    public func getAccessToken() -> AnyPublisher<FirebaseDistributionDTOs.AccessToken, NetworkingError> {
        /// Taken from https://github.com/fastlane/fastlane-plugin-firebase_app_distribution
        let clientID = "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com"

        /// Taken from https://github.com/fastlane/fastlane-plugin-firebase_app_distribution
        /// In this type of application, the client secret is not treated as a secret.
        /// See: https://developers.google.com/identity/protocols/OAuth2InstalledApp
        let clientSecret = "j9iVZfS8kkCEFUPaAeJV0sAi"

        return client
            .post("token")
            .with(headers: [
                "Content-Type": "application/json", // x-www-form-urlencoded
            ])
            .with(body: [
                "refresh_token": refreshToken,
                "client_id": clientID,
                "client_secret": clientSecret,
                "grant_type": "refresh_token",
                "scope": nil,
            ])
            .perform()
    }
}
