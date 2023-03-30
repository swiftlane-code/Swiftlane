//

import Foundation
import Git
import GitLabAPI
import Guardian
import Networking
import SwiftlaneCore
import Xcodebuild

/// High level service to modify project version in git repo.
public class ProjectVersioningService {
    private struct InfoPlistModel: Decodable {
        /// Version.
        public let CFBundleShortVersionString: String?
        /// Build number.
        public let CFBundleVersion: String?
    }

    public struct Config {
        public let projectDir: AbsolutePath
        public let commitMessagePrefix: String
        public let committeeName: String
        public let committeeEmail: String
        public let infoPlistPath: RelativePath

        public init(projectDir: AbsolutePath, commitMessagePrefix: String, committeeName: String, committeeEmail: String, infoPlistPath: RelativePath) {
            self.projectDir = projectDir
            self.commitMessagePrefix = commitMessagePrefix
            self.committeeName = committeeName
            self.committeeEmail = committeeEmail
            self.infoPlistPath = infoPlistPath
        }
    }

    private let logger: Logging
    private let filesManager: FSManaging
    private let versionConverter: ProjectVersionConverting
    private let projectPatcher: XcodeProjectPatching
    private let git: GitProtocol

    private let config: Config

    public init(
        logger: Logging,
        filesManager: FSManaging,
        versionConverter: ProjectVersionConverting,
        projectPatcher: XcodeProjectPatching,
        git: GitProtocol,
        config: Config
    ) {
        self.logger = logger
        self.filesManager = filesManager
        self.versionConverter = versionConverter
        self.projectPatcher = projectPatcher
        self.git = git
        self.config = config
    }

    public func remoteName() throws -> String {
        try git.remotes(repo: config.projectDir).first.unwrap(
            errorDescription: "git remote name is nil (expected something like \"origin\")."
        )
    }

    public func push() throws {
        logger.important("Pushing...")
        try git.push(
            repo: config.projectDir,
            refspec: try remoteName() + " HEAD", // `HEAD` to push with the same name as local branch
            options: [.setUpstream]
        )
    }

    public func checkout(branch: String, isLocalBranch: Bool) throws {
        logger.important("Checking out \(isLocalBranch ? "local" : "remote") branch \(branch.quoted)...")

        if isLocalBranch {
            try git.checkout(
                repo: config.projectDir,
                ref: branch,
                discardLocalChanges: true
            )

            try git.reset(
                repo: config.projectDir,
                .hard,
                to: nil
            )
        } else {
            try git.reset(
                repo: config.projectDir,
                toBranch: branch,
                ofRemote: try remoteName()
            )
        }
    }

    public func createReleaseBranch(for releaseVersion: SemVer, from branch: String) throws -> String {
        let newBranchName = "release/\(releaseVersion.string(format: .atLeastMajorMinor))"
        try createLocalBranch(named: newBranchName, from: branch)
        return newBranchName
    }

    private func createLocalBranch(named branchName: String, from sourceRef: String) throws {
        logger.important("Creating branch \(branchName.quoted)...")

        try git.fetch(
            repo: config.projectDir,
            allRemotes: true
        )

        let remoteSourceName = try remoteName().appendingPathComponent(sourceRef)

        try git.createBranch(
            repo: config.projectDir,
            name: branchName,
            startPoint: remoteSourceName,
            resetIfExists: true,
            discardLocalChanges: true
        )
    }

    /// Change version in currently checked out branch, then make a commit.
    public func changeVersion(to newVersion: SemVer) throws {
        let oldVersion = try readCurrentVersionFromFile()
        let oldVersionStr = oldVersion.string(format: .atLeastMajorMinor)
        let newVersionStr = newVersion.string(format: .atLeastMajorMinor)

        logger.important("Changing version from \(oldVersionStr.lightMagenta) to \(newVersionStr.lightMagenta)...")

        let newVersionFullValue = try versionConverter.convertAppVersionToPlistValue(newVersion)

        try projectPatcher.setMarketingVersionForAllTargets(
            projectDir: config.projectDir,
            marketingVersion: String(newVersionFullValue)
        )

        let commitMessage = "\(config.commitMessagePrefix) from \(oldVersionStr) to \(newVersionStr)"

        try git.add(
            repo: config.projectDir,
            "*.plist",
            force: false,
            ignoreRemoved: false
        )

        try git.commit(
            repo: config.projectDir,
            message: commitMessage,
            userName: config.committeeName,
            userEmail: config.committeeEmail
        )

        logger.success("Version changed from \(oldVersionStr.lightMagenta) to \(newVersionStr.lightMagenta)")
    }

    public func readCurrentVersionFromFile() throws -> SemVer {
        let fullPath = config.projectDir.appending(path: config.infoPlistPath)
        let plistData = try filesManager.readData(fullPath, log: true)
        let decoder = PropertyListDecoder()
        let plistModel = try decoder.decode(InfoPlistModel.self, from: plistData)
        let version = try versionConverter.convertAppVersionFromPlistValue(plistModel.CFBundleShortVersionString)
        return version
    }
}
