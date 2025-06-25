//

import Foundation

import AppStoreConnectAPI
import Provisioning
import Simulator
import SwiftlaneCore
import Xcodebuild

public struct CertsImportTaskConfig {
    public let common: CertsCommonConfig
    public let certsToImport: [Path]
    public let allowOverwrite: Bool
}

public final class CertsImportTask {
    public enum Errors: Error {
        case emptyCertsList
        case certAlreadyExists(Path)
    }

    private let logger: Logging
    private let shell: ShellExecuting
    private let repo: CertsRepositoryProtocol
    private let passwordReader: PasswordReading
    private let filesManager: FSManaging

    private let config: CertsImportTaskConfig

    public init(
        logger: Logging,
        shell: ShellExecuting,
        repo: CertsRepositoryProtocol,
        passwordReader: PasswordReading,
        filesManager: FSManaging,
        config: CertsImportTaskConfig
    ) {
        self.logger = logger
        self.shell = shell
        self.repo = repo
        self.passwordReader = passwordReader
        self.filesManager = filesManager
        self.config = config
    }

    public func run() throws {
        if config.certsToImport.isEmpty {
            logger.error("Supplied cert import list is empty.")
            throw Errors.emptyCertsList
        }

        // clone repo

        let clonedRepoPath = try config.common.clonedRepoDir.appending(path: "certs-repo_" + Date().full_custom)

        defer {
            try? filesManager.delete(clonedRepoPath)
        }

        try repo.cloneAndDecryptRepo(
            repoURL: config.common.repoURL,
            repoBranch: config.common.repoBranch,
            encryptionPassword: config.common.encryptionPassword,
            clonedRepoPath: clonedRepoPath
        )

        // import certs

        for filePath in config.certsToImport {
            let filePathAbs = filePath.makeAbsoluteIfIsnt(relativeTo: try filesManager.pwd())
            let targetDir = filePath.pathExtension == "p8" ? "authKeys" : "certs"
            let importedPathPart = try RelativePath(targetDir).appending(path: filePath.lastComponent)
            let importedPath: AbsolutePath = clonedRepoPath.appending(path: importedPathPart)

            logger.important("Will add \(filePathAbs.string.quoted) to \(importedPath.string.quoted)")

            if filesManager.fileExists(importedPath) {
                if config.allowOverwrite {
                    logger.warn("File \(importedPathPart.string.quoted) already exists. Overwriting...")
                    try filesManager.delete(importedPath)
                } else {
                    throw Errors.certAlreadyExists(.relative(importedPathPart))
                }
            }

            if !filesManager.directoryExists(importedPath.deletingLastComponent) {
                try filesManager.mkdir(importedPath.deletingLastComponent)
            }
            try filesManager.copy(filePathAbs, to: importedPath)
            repo.markFileAsChanged(clonedRepoPath: clonedRepoPath, filePath: importedPathPart)
        }

        // encrypt with imported files

        let importedList = config.certsToImport
            .map {
                $0.lastComponent.string.quoted
            }.joined(separator: ", ")

        try repo.encryptRepoAndCommitChanges(
            clonedRepoPath: clonedRepoPath,
            encryptionPassword: config.common.encryptionPassword,
            supposeEverythingChanged: false,
            commitMessage: "Imported: " + importedList
        )
    }
}
