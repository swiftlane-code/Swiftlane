
import Foundation
import GitLabAPI
import Guardian
import Network
import SwiftlaneCore

// sourcery: AutoMockable
public protocol FilesChecking {
    func checkStopListFiles(stopList: [StringMatcher]) throws
}

public extension FilesChecker {
    struct Files: Decodable {
        public let gitignoreFiles: [StringMatcher]
        public let stopList: [StringMatcher]
        public let otherFiles: [StringMatcher]
    }
}

public extension FilesChecker {
    struct BadFileInfo: Equatable {
        let file: String
    }
}

public final class FilesChecker {
    private let logger: Logging
    private let gitlabCIEnvironment: GitLabCIEnvironmentReading
    private let gitlabApi: GitLabAPIClientProtocol
    private let reporter: FilesCheckerReporting

    public init(
        logger: Logging,
        gitlabCIEnvironment: GitLabCIEnvironmentReading,
        gitlabApi: GitLabAPIClientProtocol,
        reporter: FilesCheckerReporting
    ) {
        self.logger = logger
        self.gitlabCIEnvironment = gitlabCIEnvironment
        self.gitlabApi = gitlabApi
        self.reporter = reporter
    }

    private func getDiff() throws -> RepositoryCompareResult {
        try gitlabApi.repositoryDiff(
            projectId: try gitlabCIEnvironment.int(.CI_PROJECT_ID),
            source: try gitlabCIEnvironment.string(.CI_MERGE_REQUEST_SOURCE_BRANCH_NAME),
            target: try gitlabCIEnvironment.string(.CI_MERGE_REQUEST_TARGET_BRANCH_NAME)
        ).await()
    }
}

extension FilesChecker: FilesChecking {
    public func checkStopListFiles(stopList: [StringMatcher]) throws {
        let changes = try getDiff().diffs.map(\.newPath)

        logger.important("Changed files: \(changes)")

        let findedLockFiles = changes
            .filter { stopList.isMatching(string: $0) }
            .map { BadFileInfo(file: $0) }

        guard findedLockFiles.isEmpty else {
            return reporter.reportFailsDetected(findedLockFiles)
        }

        return reporter.reportSuccess()
    }
}
