//

import AppStoreConnectJWT
import Foundation
import SwiftlaneCore

public protocol AppStoreConnectAuthKeyIDParsing {
    /// Returns the `XXX` part of `AuthKey_XXX.p8` file name.
    /// - Parameter keyPath: name of `AuthKey_XXX.p8` file.
    func apiKeyID(from apiKeyFileName: String) throws -> String

    func apiKeyID(from apiKeyPath: AbsolutePath) throws -> String
}

public final class AppStoreConnectAuthKeyIDParser: AppStoreConnectAuthKeyIDParsing {
    public init() {}

    public func apiKeyID(from apiKeyPath: AbsolutePath) throws -> String {
        try apiKeyID(from: apiKeyPath.lastComponent.string)
    }

    public func apiKeyID(from apiKeyFileName: String) throws -> String {
        let apiKeyRegex = try NSRegularExpression(pattern: #"^AuthKey_(\w+).p8$"#)
        let apiKeyID = try apiKeyRegex.firstMatchGroups(in: apiKeyFileName).unwrap(
            errorDescription: "Unable to parse auth key id from \(apiKeyFileName.quoted) using regex \(apiKeyRegex.pattern.quoted)"
        )[1]
        return String(apiKeyID)
    }
}

public final class AppStoreConnectTokenGenerator {
    private let jwtGenerator: AppStoreConnectJWTGenerator

    public init(
        filesManager: FSManaging,
        authKeyIDParser: AppStoreConnectAuthKeyIDParsing,
        jwtGenerator: AppStoreConnectJWTGenerator,
        authKeyPath: AbsolutePath,
        authKeyIssuerID: String
    ) throws {
        self.jwtGenerator = jwtGenerator

        let apiKeyData = try filesManager.readData(authKeyPath, log: true)
        let apiKeyID = try authKeyIDParser.apiKeyID(from: authKeyPath.lastComponent.string)

        config = .init(keyIdentifier: apiKeyID, issuerID: authKeyIssuerID, privateKey: apiKeyData)
    }

    private var token: AppStoreConnectJWTToken?
    private let config: AppStoreConnectJWTGenerator.Config

    private func generateTokenIfNeeded(lifetime _: TimeInterval?) throws -> AppStoreConnectJWTToken {
        if let token = token, !token.isExpired() {
            return token
        }
        let token = try jwtGenerator.generateToken(
            config: config,
            creationTime: Date(),
            scope: nil
        )
        self.token = token
        return token
    }

    /// Generates signed JWT token.
    ///
    /// Pass `nil` to `tokenLifetime` to use value from `self.config.tokenLifetime`.
    ///
    /// Docs: https://developer.apple.com/documentation/appstoreconnectapi/generating_tokens_for_api_requests
    ///
    /// - Parameter lifetime: time period generated token can be used for.
    /// In most cases App Store Connect will refuse token with lifetime greater than 20 minutes (1200 seconds).
    ///
    /// - Returns: Signed JWT token.
    public func token(lifetime: TimeInterval? = nil) throws -> AppStoreConnectJWTToken {
        try generateTokenIfNeeded(lifetime: lifetime)
    }
}
