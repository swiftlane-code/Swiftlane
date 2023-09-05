
import Foundation
import Git
import Guardian
import Networking
import SwiftlaneCore
import Xcodebuild

public extension ChangeVersionTask {
    struct Config {
        public enum ChangeVersionStrategy {
            case bumpMajor
            case bumpMinor
            case bumpPatch
        }

        public let sourceBranchName: String
        public let bumpStrategy: ChangeVersionStrategy
    }
}

public extension ChangeVersionTask {
    enum Errors: Error {
        case errorBumpAppVersionParseFile
    }
}

public final class ChangeVersionTask {
    private let logger: Logging
    private let versioningService: ProjectVersioningService
    private let config: Config

    public init(
        logger: Logging,
        versioningService: ProjectVersioningService,
        config: Config
    ) {
        self.logger = logger
        self.versioningService = versioningService
        self.config = config
    }

    // MARK: Public

    public func run() throws {
        try versioningService.checkout(branch: config.sourceBranchName, isLocalBranch: false)
        let currentVersion = try versioningService.readCurrentVersionFromFile()
        let oldVersionStr = currentVersion.string(format: .atLeastMajorMinor)
        logger.important("Current version is \(oldVersionStr)")

        let targetVersion: SemVer = {
            switch config.bumpStrategy {
            case .bumpMajor:
                return SemVer(currentVersion.major + 1, 0, 0)
            case .bumpMinor:
                return SemVer(currentVersion.major, currentVersion.minor + 1, 0)
            case .bumpPatch:
                return SemVer(currentVersion.major, currentVersion.minor, currentVersion.patch + 1)
            }
        }()

        try versioningService.changeVersion(to: targetVersion)
        try versioningService.push()

        let newVersionStr = targetVersion.string(format: .atLeastMajorMinor)
        logger.success("Version changed from \(oldVersionStr.lightMagenta) to \(newVersionStr.lightMagenta) successfully!")
    }
}
