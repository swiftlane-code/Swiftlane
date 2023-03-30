//

import Combine
import Foundation
import Networking
import SwiftlaneCore

public class MattermostAPIClient {
    let client: NetworkingClient

    public init(client: NetworkingClient) {
        self.client = client
    }

    public convenience init(baseURL: URL, logger: Logging, logLevel: LoggingLevel = .silent) {
        let client = NetworkingClient(
            baseURL: baseURL,
            configuration: .default,
            logger: NetworkingLogger(
                logLevel: logLevel,
                logger: logger
            )
        )
        client.commonHeaders = ["Content-Type": "application/json"]
        self.init(client: client)
    }

    /// https://developers.mattermost.com/integrate/webhooks/incoming/
    public func postWebhook<T: Encodable>(hookKey: String, body: T) throws -> AnyPublisher<Void, NetworkingError> {
        client.post("hooks/" + hookKey)
            .with(body: body)
            .perform()
    }
}
