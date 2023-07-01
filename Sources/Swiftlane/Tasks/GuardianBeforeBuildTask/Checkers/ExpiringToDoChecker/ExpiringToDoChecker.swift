//

import Foundation
import GitLabAPI
import Guardian
import SwiftlaneCore

public protocol ExpiringToDoChecking {
    func checkExpiringToDos() throws
}

public struct ExpiringToDoConfig {
    public let enabled: Bool
    public let projectDir: AbsolutePath
    public let excludeFilesPaths: [StringMatcher]
    public let excludeFilesNames: [StringMatcher]
    public let maxFutureDays: Int?

    /// Do not check when Merge Request Source Branch is one of these.
    public let ignoreCheckForSourceBranches: [StringMatcher]

    /// Do not check when Merge Request Target Branch is one of these.
    public let ignoreCheckForTargetBranches: [StringMatcher]

    /// Used to fetch list of users who can be assigned as an author of a TODO
    public let gitlabGroupIDToFetchMembersFrom: Int
}

public final class ExpiringToDoChecker {
    private let filesManager: FSManaging
    private let reporter: ExpiringToDoReporting
    private let config: ExpiringToDoConfig
    private let expiringToDoParser: ExpiringToDoParsing
    private let expiringToDoVerifier: ExpiringToDoVerifiing
    private let gitlabCIEnvironmentReader: GitLabCIEnvironmentReading
    private let gitlabApi: GitLabAPIClientProtocol
    private let logger: Logging

    public init(
        filesManager: FSManaging,
        reporter: ExpiringToDoReporting,
        expiringToDoParser: ExpiringToDoParsing,
        expiringToDoVerifier: ExpiringToDoVerifiing,
        gitlabCIEnvironmentReader: GitLabCIEnvironmentReading,
        gitlabApi: GitLabAPIClientProtocol,
        logger: Logging,
        config: ExpiringToDoConfig
    ) {
        self.filesManager = filesManager
        self.reporter = reporter
        self.expiringToDoParser = expiringToDoParser
        self.expiringToDoVerifier = expiringToDoVerifier
        self.gitlabCIEnvironmentReader = gitlabCIEnvironmentReader
        self.gitlabApi = gitlabApi
        self.logger = logger
        self.config = config
    }

    private func groupMembers() throws -> [Member] {
        try gitlabApi.groupMembers(
            group: .init(id: config.gitlabGroupIDToFetchMembersFrom)
        ).await()
    }

    private func groupDetails() throws -> Group {
        try gitlabApi.groupDetails(
            group: .init(id: config.gitlabGroupIDToFetchMembersFrom)
        ).await()
    }

    private func mergeRequestAuthor() throws -> Member {
        let mergeRequest = try gitlabApi.mergeRequest(
            projectId: try gitlabCIEnvironmentReader.int(.CI_PROJECT_ID),
            mergeRequestIid: try gitlabCIEnvironmentReader.int(.CI_MERGE_REQUEST_IID),
            loadChanges: false
        ).await()

        let author = try mergeRequest.author
            .unwrap(errorDescription: "Unable to get Merge Request author")

        return author
    }

    private func allowedToDoAuthors() throws -> [String] {
        let gitlabMembers = try groupMembers()
            .filter { !$0.username.contains("r2d2") }
            .map(\.username)

        logger.debug("GitLab group has \(gitlabMembers.count) members: \(gitlabMembers)")
        return gitlabMembers
    }
}

extension ExpiringToDoChecker: ExpiringToDoChecking {
    public func checkExpiringToDos() throws {
        guard config.enabled else {
            reporter.reportExpiredToDoCheckerDisabled()
            return
        }

        let sourceBranch = try gitlabCIEnvironmentReader.string(.CI_MERGE_REQUEST_SOURCE_BRANCH_NAME)
        let targetBranch = try gitlabCIEnvironmentReader.string(.CI_MERGE_REQUEST_TARGET_BRANCH_NAME)

        guard !config.ignoreCheckForSourceBranches.isMatching(string: sourceBranch) else {
            reporter.reportCheckIsDisabledForSourceBranch(sourceBranch: sourceBranch)
            return
        }

        guard !config.ignoreCheckForTargetBranches.isMatching(string: targetBranch) else {
            reporter.reportCheckIsDisabledForTargetBranch(targetBranch: targetBranch)
            return
        }

        logger.important("Checking expiring TODOs...")

        let swiftFiles = try filesManager.find(config.projectDir)
            .filter { $0.hasSuffix(".swift") }
            .compactMap { [self] filePath in
                (try? filePath.relative(to: config.projectDir)).map {
                    (filePath, $0)
                }
            }
            .filter { [self] _, relative in
                !config.excludeFilesPaths.isMatching(string: relative.string)
                    && !config.excludeFilesNames.isMatching(string: relative.lastComponent.string)
            }

        let mergeRequestAuthor = try mergeRequestAuthor()
        logger.important("Merge Request author: \(mergeRequestAuthor.username.quoted)")

        logger.important("Parsing \(swiftFiles.count) swift files...")

        let allToDos = try swiftFiles.flatMap { filePath, relativePath in
            try expiringToDoParser.parseToDos(
                from: filesManager.readText(filePath, log: true),
                fileName: relativePath
            )
        }.map {
            try expiringToDoVerifier.verify(
                todo: $0,
                maxFutureDays: config.maxFutureDays,
                allowedAuthors: try allowedToDoAuthors(),
                userToBeBlocked: mergeRequestAuthor.username
            )
        }

        logger.important("Found \(allToDos.count) TODOs.")
        logger.verbose(allToDos.asPrettyJSON())

        logger.debug("Forming Guardian report...")
        reporter.report(todos: allToDos)
        reporter.reportSuccessIfNeeded()
    }
}
