
import Foundation
import Git
import GitLabAPI
import Guardian
import Networking
import SwiftlaneCore
import Xcodebuild

public extension UploadGitLabPackageTask {
    struct Config {
        public let projectID: UInt
        public let packageName: String
        public let packageVersion: String
        public let file: AbsolutePath
        public let uploadedFileName: String?
        public let timeoutSeconds: TimeInterval
    }
}

public final class UploadGitLabPackageTask {
    public enum Errors: Error {
        case packageAlreadyExists(package: Package)
    }

    private let logger: Logging
    private let progressLogger: NetworkingProgressLogger
    private let filesManager: FSManaging
    private let gitlabApi: GitLabAPIClientProtocol
    private let timeMeasurer: TimeMeasuring
    private let config: Config

    public init(
        logger: Logging,
        progressLogger: NetworkingProgressLogger,
        filesManager: FSManaging,
        gitlabApi: GitLabAPIClientProtocol,
        timeMeasurer: TimeMeasuring,
        config: Config
    ) {
        self.logger = logger
        self.progressLogger = progressLogger
        self.filesManager = filesManager
        self.gitlabApi = gitlabApi
        self.timeMeasurer = timeMeasurer
        self.config = config
    }

    // MARK: Public

    public func run() throws {
        // check if exists

        logger.info("Checking if the same package already exists...")

        let existingPackage = try gitlabApi.listPackages(
            space: .project(id: Int(config.projectID)),
            request: PackagesListRequest.make {
                $0.package_name = config.packageName
            }
        ).await().first(where: { package in
            package.name == config.packageName && package.version == config.packageVersion
        })

        if let existingPackage = existingPackage {
            logger.error("Package with the same name and version already exists: \(existingPackage.asPrettyJSON())")
            logger.error("Upload cancelled")
            throw Errors.packageAlreadyExists(package: existingPackage)
        }

        // upload

        try timeMeasurer.measure(description: "Uploading package") {
            let data = try filesManager.readData(config.file, log: true)

            let publisher = gitlabApi.uploadPackage(
                space: .project(id: Int(config.projectID)),
                name: config.packageName,
                version: config.packageVersion,
                fileName: config.uploadedFileName ?? config.file.lastComponent.string,
                data: data,
                timeout: config.timeoutSeconds
            )

            let result = try progressLogger.performLoggingProgress(
                description: "Uploading progress: ",
                publisher: publisher,
                timeout: config.timeoutSeconds
            )

            logger.success(result.asPrettyJSON())
        }

        logger.success("Package successfully uploaded.")
    }
}
