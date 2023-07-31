//

import SwiftlaneCore

public struct WarningLimitsCheckerConfig {
    public let projectDir: AbsolutePath
    public let swiftlintConfigPath: AbsolutePath
    public let trackingPushRemoteName: String /// e.g. `"origin"`
    public let trackingNewFoldersCommitMessage: String
    public let loweringWarningLimitsCommitMessage: String
    public let committeeName: String
    public let committeeEmail: String
    public let testableTargetsListFile: Path
}
