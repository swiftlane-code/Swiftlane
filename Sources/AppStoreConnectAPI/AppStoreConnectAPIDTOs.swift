//

import Bagbutik_Models
import Foundation

public enum AppStoreConnectAPIDTOs {
    public struct BundleID: Codable, Equatable {
        public let name: String
        /// bundle id itself.
        public let identifier: String
        public let appStoreConnectID: String
    }

    public struct ReleasedAppStoreVersion {
        public let appStoreState: AppStoreVersionState
        public let appStoreVersion: String
        public let buildVersion: String
        public let buildNumber: String
    }
}
