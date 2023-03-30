//

import AppStoreConnectJWT
import Bagbutik_Core
import Combine
import Foundation
import Networking

public class AppStoreConnectAPIClient: AppStoreConnectAPIClientProtocol {
    let bagbutikService: BagbutikServiceProtocol

    public init(
        bagbutikService: BagbutikServiceProtocol
    ) {
        self.bagbutikService = bagbutikService
    }
}

public extension AppStoreConnectAPIClient {
    convenience init(
        keyId: String,
        issuerId: String,
        privateKey: String
    ) throws {
        let urlSession = URLSession(configuration: .ephemeral)
        let bagbutikService = BagbutikService(
            jwt: try JWT(keyId: keyId, issuerId: issuerId, privateKey: privateKey),
            fetchData: urlSession.data(for:delegate:)
        )

        self.init(bagbutikService: bagbutikService)
    }

    convenience init(
        keyId: String,
        issuerId: String,
        privateKeyPath: String
    ) throws {
        let urlSession = URLSession(configuration: .ephemeral)
        let bagbutikService = BagbutikService(
            jwt: try JWT(keyId: keyId, issuerId: issuerId, privateKeyPath: privateKeyPath),
            fetchData: urlSession.data(for:delegate:)
        )

        self.init(bagbutikService: bagbutikService)
    }
}
