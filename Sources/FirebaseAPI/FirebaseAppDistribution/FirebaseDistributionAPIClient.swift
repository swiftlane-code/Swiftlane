//

import Combine
import Foundation
import Networking
import SwiftlaneCore

public extension FirebaseDistributionAPIClient {
    convenience init(
        firebaseAppID: String,
        logger: Logging,
        logLevel: LoggingLevel = .silent
    ) throws {
        let distributionClient = NetworkingClient(
            baseURL: URL(string: "https://firebaseappdistribution.googleapis.com")!,
            configuration: .ephemeral,
            logger: NetworkingLogger(
                logLevel: logLevel,
                logger: logger
            )
        )

        try self.init(
            distributionClient: distributionClient,
            firebaseAppID: firebaseAppID
        )
    }
}

/// Based on: https://github.com/fastlane/fastlane-plugin-firebase_app_distribution/blob/master/lib/fastlane/plugin/firebase_app_distribution/client/firebase_app_distribution_api_client.rb
public final class FirebaseDistributionAPIClient {
    /// Client used to perform FirebaseDistribution API requests.
    let distributionClient: NetworkingClientProtocol

    /// Looks like `1:1234567890:ios:0a1b2c3d4e5f67890`.
    let firebaseAppID: String

    /// Second part of appID split by `:`.
    /// Example: `1234567890` from app id `1:1234567890:ios:0a1b2c3d4e5f67890`.
    let firebaseProjectID: String

    /// - Parameters:
    ///   - authClient: Client used to get access token from Google's OAuth2 using `refreshToken`.
    ///   - distributionClient: Client used to perform FirebaseDistribution API requests.
    ///   - refreshToken: This is your token from `login:ci` command from
    ///   [Firebase CLI Tools](https://firebase.google.com/docs/cli#cli-ci-systems)
    ///   - firebaseAppID: Looks like `1:1234567890:ios:0a1b2c3d4e5f67890`.
    public init(
        distributionClient: NetworkingClientProtocol,
        firebaseAppID: String
    ) throws {
        /// Second part of appID split by `:`.
        /// Example: `1234567890` is project id in app id `1:1234567890:ios:0a1b2c3d4e5f67890`.
        func projectID(from appId: String) throws -> String {
            // swiftformat:disable indent
			let projectId = try appId.split(separator: ":")[safe: 1].unwrap(
				errorDescription:
					"Unable to parse project id from appId \(appId.quoted). " +
					"Expected app id format: \"1:1234567890:ios:0a1b2c3d4e5f67890\""
			)
			// swiftformat:enable indent
            return String(projectId)
        }

        self.distributionClient = distributionClient
        self.firebaseAppID = firebaseAppID
        firebaseProjectID = try projectID(from: firebaseAppID)
    }
}
