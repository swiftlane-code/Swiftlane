//

import Foundation
import SwiftlaneCore

public extension GuardianBeforeBuildTask {
    struct WarningLimitsConfig {
        public let projectDir: AbsolutePath
        public let jiraTaskRegex: String
        public let swiftlintConfigPath: AbsolutePath
        public let loweringWarningLimitsCommitMessage: String
        public let trackingNewFoldersCommitMessage: String
        public let remoteName: String
        public let committeeName: String
        public let committeeEmail: String
        public let warningsStorageConfig: WarningsStorage.Config
        public let testableTargetsListFile: Path
    }
}
