//

import Foundation

public struct Package: Codable {
    public let id: Int
    public let name: String
    public let version: String
    public let packageType: PackageType
    public let status: Status
    public let _links: Links
    public let createdAt: Date
    public let tags: [String]
}

public struct PackageUploadResult: Codable {
    public let message: String

    public static let successMessage = "201 Created"
}

public extension Package {
    /// Filter the returned packages by type.
    enum PackageType: String, Codable {
        case conan
        case maven
        case npm
        case pypi
        case composer
        case nuget
        case helm
        case terraformModule = "terraform_module"
        case golang
        case generic
    }

    /// Filter the returned packages by status.
    enum Status: String, Codable {
        case `default`
        case hidden
        /// ⚠️ Working with packages that have a processing status
        /// can result in malformed data or broken packages.
        case processing
        case error
        case pendingDestruction = "pending_destruction"
    }

    struct Links: Codable {
        /// e.g. `"/ios/ios-app-packages/-/packages/403"`
        public let webPath: String
        /// e.g. `"https://gitlab.com/api/v4/projects/844/packages/403"`
        public let deleteApiPath: String
    }
}
