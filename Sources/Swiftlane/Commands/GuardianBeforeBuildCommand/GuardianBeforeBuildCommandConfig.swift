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

    public init(
        trackingPushRemoteName: String,
        trackingNewFoldersCommitMessage: String,
        loweringWarningLimitsCommitMessage: String,
        expiringTODOs: ExpiringToDos,
        stubsDeclarations: StubDeclarationConfig,
        filesNamingConfig: FilesNamingConfig,
        testableTargetsListFilePath: Path
    ) {
        self.trackingPushRemoteName = trackingPushRemoteName
        self.trackingNewFoldersCommitMessage = trackingNewFoldersCommitMessage
        self.loweringWarningLimitsCommitMessage = loweringWarningLimitsCommitMessage
        self.expiringTODOs = expiringTODOs
        self.stubsDeclarations = stubsDeclarations
        self.filesNamingConfig = filesNamingConfig
        self.testableTargetsListFilePath = testableTargetsListFilePath
    }
    
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
        
        public let blockingConfig: ExpiringToDoBlockingConfig

        public init(
            enabled: Bool,
            warningAfterDaysLeft: UInt,
            failIfExpiredDetected: Bool,
            excludeFilesPaths: [StringMatcher],
            excludeFilesNames: [StringMatcher],
            todoDateFormat: String,
            needFail: Bool,
            maxFutureDays: Int?,
            ignoreCheckForSourceBranches: [StringMatcher],
            ignoreCheckForTargetBranches: [StringMatcher],
            gitlabGroupIDToFetchMembersFrom: Int,
            blockingConfig: ExpiringToDoBlockingConfig
        ) {
            self.enabled = enabled
            self.warningAfterDaysLeft = warningAfterDaysLeft
            self.failIfExpiredDetected = failIfExpiredDetected
            self.excludeFilesPaths = excludeFilesPaths
            self.excludeFilesNames = excludeFilesNames
            self.todoDateFormat = todoDateFormat
            self.needFail = needFail
            self.maxFutureDays = maxFutureDays
            self.ignoreCheckForSourceBranches = ignoreCheckForSourceBranches
            self.ignoreCheckForTargetBranches = ignoreCheckForTargetBranches
            self.gitlabGroupIDToFetchMembersFrom = gitlabGroupIDToFetchMembersFrom
            self.blockingConfig = blockingConfig
        }
    }

    public struct StubDeclarationConfig: Decodable {
        public let enabled: Bool
        public let fail: Bool // fail or warn
        public let mocksTargetsPathRegex: String
        public let testsTargetsPathRegex: String
        public let ignoredFiles: [StringMatcher]
        
        public init(
            enabled: Bool,
            fail: Bool,
            mocksTargetsPathRegex: String,
            testsTargetsPathRegex: String,
            ignoredFiles: [StringMatcher]
        ) {
            self.enabled = enabled
            self.fail = fail
            self.mocksTargetsPathRegex = mocksTargetsPathRegex
            self.testsTargetsPathRegex = testsTargetsPathRegex
            self.ignoredFiles = ignoredFiles
        }
    }

    public struct FilesNamingConfig: Decodable {
        let allowedFilePath: [StringMatcher]
        
        public init(allowedFilePath: [StringMatcher]) {
            self.allowedFilePath = allowedFilePath
        }
    }
}
