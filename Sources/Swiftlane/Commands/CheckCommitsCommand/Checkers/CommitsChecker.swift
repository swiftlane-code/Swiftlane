
import Foundation
import Git
import GitLabAPI
import Guardian
import Network
import SwiftlaneCore

// sourcery: AutoMockable
public protocol CommitsChecking {
    func checkCommits() throws
}

public extension CommitsChecker {
    struct Config {
        public struct CommitsForCheck {
            public let name: StringMatcher
            public let commits: [String]
        }

        public let projectDir: AbsolutePath
        public let commitsForCheck: [CommitsForCheck]
    }
}

public final class CommitsChecker {
    private let logger: Logging
    private let git: GitProtocol
    private let gitlabCIEnvironment: GitLabCIEnvironmentReading
    private let reporter: CommitsCheckerReporting
    private let config: Config

    public init(
        logger: Logging,
        git: GitProtocol,
        gitlabCIEnvironment: GitLabCIEnvironmentReading,
        reporter: CommitsCheckerReporting,
        config: Config
    ) {
        self.logger = logger
        self.git = git
        self.gitlabCIEnvironment = gitlabCIEnvironment
        self.reporter = reporter
        self.config = config
    }
}

extension CommitsChecker: CommitsChecking {
    public func checkCommits() throws {
        let targetBranch = try gitlabCIEnvironment.string(.CI_MERGE_REQUEST_TARGET_BRANCH_NAME)

        let failsCommits: [String] = config.commitsForCheck
            .filter { $0.name.isMatching(targetBranch) }
            .flatMap {
                $0.commits.filter { commit in
                    do {
                        try git.checkCommitIsAncestorHead(repo: config.projectDir, commit: commit)
                    } catch {
                        logger.error("Failed checking if commit is ancestor!")
                        logger.logError(error)
                        return true
                    }
                    return false
                }
            }

        guard failsCommits.isEmpty else {
            return reporter.reportFailsDetected(failsCommits)
        }

        return reporter.reportSuccess()
    }
}
