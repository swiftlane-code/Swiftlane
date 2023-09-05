//

import Foundation
import GitLabAPI
import Guardian
import SwiftlaneCore

public struct AllowedFilePathConfig {
    public let allowedFilePath: [StringMatcher]
}

public protocol AllowedFilePathChecking {
    func checkFilesPaths() throws
}

public class AllowedFilePathChecker {
    private let logger: Logging
    private let reporter: FilePathReporting
    private let gitlabClient: GitLabAPIClientProtocol
    private let gitlabCIEnvironmentReader: GitLabCIEnvironmentReading

    private let config: AllowedFilePathConfig

    public init(
        logger: Logging,
        reporter: FilePathReporting,
        gitlabClient: GitLabAPIClientProtocol,
        gitlabCIEnvironmentReader: GitLabCIEnvironmentReading,
        config: AllowedFilePathConfig
    ) {
        self.logger = logger
        self.reporter = reporter
        self.gitlabClient = gitlabClient
        self.gitlabCIEnvironmentReader = gitlabCIEnvironmentReader
        self.config = config
    }
}

extension AllowedFilePathChecker: AllowedFilePathChecking {
    public func checkFilesPaths() throws {
        let mrChanges = try gitlabClient.mergeRequestChanges(
            projectId: gitlabCIEnvironmentReader.int(.CI_PROJECT_ID),
            mergeRequestIid: gitlabCIEnvironmentReader.int(.CI_MERGE_REQUEST_IID)
        ).await()

        let invalidFilePaths = mrChanges.changes?
            .filter {
                !$0.deletedFile
            }
            .filter {
                !config.allowedFilePath.isMatching(string: $0.newPath)
            }

        invalidFilePaths?.forEach {
            reporter.reportInvalidFilePath($0.newPath)
        }
    }
}
