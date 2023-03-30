//

import Combine
import Foundation
import Networking
import SwiftlaneCore

public class GitLabPackagesRegistry {
    private let logger: Logging
    private let progressLogger: NetworkingProgressLogger
    private let gitlabAPI: GitLabAPIClientProtocol
    private let filesManager: FSManaging

    private let gitlabProjectID: Int
    private let timeout: TimeInterval

    public init(
        logger: Logging,
        progressLogger: NetworkingProgressLogger,
        gitlabAPI: GitLabAPIClientProtocol,
        filesManager: FSManaging,
        gitlabProjectID: Int,
        timeout: TimeInterval
    ) {
        self.logger = logger
        self.progressLogger = progressLogger
        self.gitlabAPI = gitlabAPI
        self.filesManager = filesManager
        self.gitlabProjectID = gitlabProjectID
        self.timeout = timeout
    }

    public func download(
        name: String,
        version: String,
        fileName: String,
        to downloadedFilePath: AbsolutePath,
        retries: Int = 0,
        retryDelay: TimeInterval = 10
    ) throws {
        let publisher = gitlabAPI.downloadPackage(
            space: .project(id: gitlabProjectID),
            name: name,
            version: version,
            fileName: fileName,
            timeout: timeout
        )
        .retry(
            retries,
            delay: .seconds(retryDelay),
            onRetry: { [logger] in
                logger.warn("Retrying download (\($0)/\($1))...")
            },
            onError: { [logger] error in
                logger.logError(error)
                logger.warn("Retrying download in \(retryDelay) seconds...")
            }
        )
        .eraseToAnyPublisher()

        let fileData: Data = try progressLogger.performLoggingProgress(
            description: "Downloading \(fileName) from package \(name) \(version): ",
            publisher: publisher,
            timeout: timeout
        )

        try filesManager.write(downloadedFilePath, data: fileData)

        logger.success("Downloaded successfully.")
    }
}
