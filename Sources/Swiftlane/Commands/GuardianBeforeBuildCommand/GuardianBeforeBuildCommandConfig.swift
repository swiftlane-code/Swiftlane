//

import Foundation
import SwiftlaneCore

public struct GuardianBeforeBuildCommandConfig: Decodable {
    // MARK: Warning Limits

    public let trackingPushRemoteName: String /// e.g. `"origin"`
    public let trackingNewFoldersCommitMessage: String
    public let loweringWarningLimitsCommitMessage: String

    public let expiringTODOs: ExpiringToDos
    public let stubsDeclarations: StubDeclarationConfig
    public let filesNamingConfig: FilesNamingConfig
    public let testableTargetsListFilePath: Path

    public struct ExpiringToDos: Decodable {
        public let enabled: Bool
        public let warningAfterDaysLeft: UInt
        public let failIfExpiredDetected: Bool
        public let excludeFilesPaths: [StringMatcher]
        public let excludeFilesNames: [StringMatcher]
        public let todoDateFormat: String
        // Fail if expired todos or invalid date format detected.
        public let needFail: Bool
        public let maxFutureDays: Int?

        /// Do not check when Merge Request Source Branch is one of these.
        public let ignoreCheckForSourceBranches: [StringMatcher]

        /// Do not check when Merge Request Target Branch is one of these.
        public let ignoreCheckForTargetBranches: [StringMatcher]

        /// Used to fetch list of users who can be assigned as an author of a TODO
        /// You can only assign a TODO's author from members of the group
        public let gitlabGroupIDToFetchMembersFrom: Int

        public let blockingConfigPath: String

        private enum CodingKeys: String, CodingKey {
            case enabled
            case warningAfterDaysLeft
            case failIfExpiredDetected
            case excludeFilesPaths
            case excludeFilesNames
            case todoDateFormat
            case needFail
            case maxFutureDays
            case ignoreCheckForSourceBranches
            case ignoreCheckForTargetBranches
            case blockingConfigPath
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            enabled = try container.decode(Bool.self, forKey: .enabled)
            warningAfterDaysLeft = try container.decode(UInt.self, forKey: .warningAfterDaysLeft)
            failIfExpiredDetected = try container.decode(Bool.self, forKey: .failIfExpiredDetected)
            excludeFilesPaths = try container.decode([StringMatcher].self, forKey: .excludeFilesPaths)
            excludeFilesNames = try container.decode([StringMatcher].self, forKey: .excludeFilesNames)
            todoDateFormat = try container.decode(String.self, forKey: .todoDateFormat)
            needFail = try container.decode(Bool.self, forKey: .needFail)
            maxFutureDays = try container.decode(Int?.self, forKey: .maxFutureDays)
            ignoreCheckForSourceBranches = try container.decode([StringMatcher].self, forKey: .ignoreCheckForSourceBranches)
            ignoreCheckForTargetBranches = try container.decode([StringMatcher].self, forKey: .ignoreCheckForTargetBranches)
            blockingConfigPath = try container.decode(String.self, forKey: .blockingConfigPath)

            gitlabGroupIDToFetchMembersFrom = try EnvironmentValueReader().int(ShellEnvKey.GITLAB_GROUP_DEV_TEAM_ID_TO_FETCH_MEMBERS)
        }
    }

    public struct StubDeclarationConfig: Decodable {
        let enabled: Bool
        let fail: Bool // fail or warn
        let mocksTargetsPath: String
        let testsTargetsPath: String
        let ignoredFiles: [StringMatcher]
    }

    public struct FilesNamingConfig: Decodable {
        let allowedFilePath: [StringMatcher]
    }
}
