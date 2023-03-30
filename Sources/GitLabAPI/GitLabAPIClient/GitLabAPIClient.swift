//

import Combine
import Foundation
import Networking
import SwiftlaneCore

public class GitLabAPIClient: GitLabAPIClientProtocol {
    let client: NetworkingClientProtocol

    public init(networkingClient: NetworkingClientProtocol) {
        client = networkingClient
    }
}

public extension GitLabAPIClient {
    /// - Parameters:
    ///   - accessTokenHeaderKey: if you are using `CI_JOB_TOKEN` then set this to `"JOB-TOKEN"` instead of `"PRIVATE-TOKEN"`.
    convenience init(
        baseURL: URL,
        accessToken: String,
        accessTokenHeaderKey: String = "PRIVATE-TOKEN",
        logLevel: LoggingLevel = .silent,
        logger: Logging
    ) {
        let networkingClient = NetworkingClient(
            baseURL: baseURL,
            deserializer: GitLabAPIDeserializer(),
            logger: NetworkingLogger(
                logLevel: logLevel,
                logger: logger
            )
        )

        networkingClient.commonHeaders = [
            accessTokenHeaderKey: accessToken,
            "Content-Type": "application/json",
        ]

        self.init(networkingClient: networkingClient)
    }
}
