//

import Foundation
import SwiftlaneCore

/// Mobile Provisioning Profile data model.
///
/// Can be parsed from `.mobileprovision` (iOS) or `.provisionprofile` (macOS) file (see `MobileProvisionParser`).
///
/// Supports both iOS and macOS provisioning profiles.
public struct MobileProvision: Codable, Equatable {
    public let AppIDName: String
    public let ApplicationIdentifierPrefix: [String]
    public let CreationDate: Date
    public let Platform: [String]
    public let IsXcodeManaged: Bool
    public let ExpirationDate: Date
    public let Name: String
    public let TeamIdentifier: [String]
    public let Entitlements: MobileProvisionEntitlements
    public let TeamName: String
    public let TimeToLive: Int
    public let UUID: String
    public let Version: Int

    public let DeveloperCertificates: [Data]

    public var applicationBundleID: String {
        ApplicationIdentifierPrefix.reduce(into: Entitlements.applicationIdentifier) {
            $0.replaceOccurrences(of: $1 + ".", with: "")
        }
    }

    /// [String: VALUE] // where VALUE can be of type Bool/Array/String
    public struct MobileProvisionEntitlements: Codable, Equatable {
        public let applicationIdentifier: String

        enum CodingKeys: String, CodingKey {
            case applicationIdentifier = "application-identifier"
            case macApplicationIdentifier = "com.apple.application-identifier"
        }

        public init(applicationIdentifier: String) {
            self.applicationIdentifier = applicationIdentifier
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // Try iOS key first, then fallback to macOS key
            if let iOSIdentifier = try? container.decode(String.self, forKey: .applicationIdentifier) {
                applicationIdentifier = iOSIdentifier
            } else if let macOSIdentifier = try? container.decode(String.self, forKey: .macApplicationIdentifier) {
                applicationIdentifier = macOSIdentifier
            } else {
                throw DecodingError.keyNotFound(
                    CodingKeys.applicationIdentifier,
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Expected either 'application-identifier' (iOS) or 'com.apple.application-identifier' (macOS)"
                    )
                )
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(applicationIdentifier, forKey: .applicationIdentifier)
        }
    }
}
