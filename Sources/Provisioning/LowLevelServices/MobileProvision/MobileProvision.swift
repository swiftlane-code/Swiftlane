//

import Foundation
import SwiftlaneCore

/// iOS Mobile Provisioning Profile data model.
///
/// Can be parsed from `.mobileprovision` file (see `MobileProvisionParser`).
///
/// Info: MacOS Provisioning Profile have different file extension `.provisionprofile`.
/// MacOS Provisioning Profiles have slightly different data structure
/// and they should be installed in a different way.
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
        }
    }
}
