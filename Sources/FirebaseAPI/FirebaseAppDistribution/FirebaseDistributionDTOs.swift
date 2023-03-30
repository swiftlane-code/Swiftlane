//

import Foundation

/// DTOs for Firebase App Distribution API.
public enum FirebaseDistributionDTOs {
    public enum UploadReleaseResult: String, Codable {
        /// Upload binary result unspecified
        case unspecified = "UPLOAD_RELEASE_RESULT_UNSPECIFIED"
        /// Upload binary resulted in a new release
        case releaseCreated = "RELEASE_CREATED"
        /// Upload binary updated an existing release
        case releaseUpdated = "RELEASE_UPDATED"
        /// Upload binary resulted in a no-op. A release with the exact same binary already exists.
        case releaseUnmodified = "RELEASE_UNMODIFIED"
    }

    /// Expires after one hour.
    public struct AccessToken: Codable {
        public let accessToken: String
        public let expiresIn: Int
        public let scope: String
        public let tokenType: String
        public let idToken: String
    }

    public struct UploadReleaseOperation: Codable {
        /// Upload operation name.
        public let name: String
    }

    /// https://firebase.google.com/docs/reference/app-distribution/rest/v1/projects.apps.releases.operations
    public struct UploadReleaseStatus: Codable {
        /// Upload operation name.
        public let name: String
        public let done: Bool?
        public let response: Response?
        public let error: ErrorObject?

        /// https://firebase.google.com/docs/reference/app-distribution/rest/v1/UploadReleaseResponse
        public struct Response: Codable {
            public let result: UploadReleaseResult
            public let release: Release?
        }

        public struct ErrorObject: Codable {
            public let message: String
        }
    }

    /// https://firebase.google.com/docs/reference/app-distribution/rest/v1/projects.apps.releases#ReleaseNotes
    public struct Release: Codable, CustomStringConvertible {
        public let name: String
        public let displayVersion: String
        public let buildVersion: String
        public let createTime: String

        public var description: String {
            "\(displayVersion) (\(buildVersion)) uploaded at \(createTime)"
        }
    }
}
