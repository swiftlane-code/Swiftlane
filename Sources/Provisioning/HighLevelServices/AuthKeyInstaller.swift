//

import Foundation
import SwiftlaneCore

public protocol AuthKeysInstalling {
  func installAuthKeys(
    from sourceDir: AbsolutePath,
    to targetDir: AbsolutePath,
    overwrite: Bool
  ) throws -> [(source: AbsolutePath, destination: AbsolutePath)]
}

public class AuthKeysInstaller {
  private let logger: Logging
  private let filesManager: FSManaging

  public init(logger: Logging, filesManager: FSManaging) {
    self.logger = logger
    self.filesManager = filesManager
  }
}

extension AuthKeysInstaller: AuthKeysInstalling {
  /// Recursively traverses `sourceDir` and copies all found files into `targetDir`.
  /// Maintains the directory structure from the source.
  ///
  /// - Parameters:
  ///   - sourceDir: Source directory to copy from
  ///   - targetDir: Target directory to copy to
  ///   - overwrite: Whether to overwrite existing files. Defaults to false.
  /// - Throws: Error if copying fails or directories don't exist
  /// - Returns: Array of copied file paths (source, destination) pairs
  public func installAuthKeys(
    from sourceDir: AbsolutePath,
    to targetDir: AbsolutePath,
    overwrite: Bool
  ) throws -> [(source: AbsolutePath, destination: AbsolutePath)] {
    logger.important("Installing auth keys...")

    guard filesManager.directoryExists(sourceDir) else {
      logger.warn("Source directory \(sourceDir.string.quoted) does not exist.")
      return []
    }

    // Create target directory if it doesn't exist
    if !filesManager.directoryExists(targetDir) {
      logger.info("Creating target directory \(targetDir.string.quoted)")
      try filesManager.mkdir(targetDir)
    }

    // Find all files in source directory recursively
    let allFiles = try filesManager.find(sourceDir)

    logger.important("Going to copy \(allFiles.count) files from \(sourceDir.string.quoted) to \(targetDir.string.quoted)")

    if allFiles.isEmpty {
      logger.warn("No files found in \(sourceDir.string.quoted)")
      return []
    }

    var copiedFiles: [(source: AbsolutePath, destination: AbsolutePath)] = []

    for sourceFile in allFiles {
      // Calculate relative path from source directory
      let relativePath = try sourceFile.relative(to: sourceDir)
      let destinationFile = targetDir.appending(path: relativePath)

      // Create intermediate directories if needed
      let destinationDir = destinationFile.deletingLastComponent
      if !filesManager.directoryExists(destinationDir) {
        try filesManager.mkdir(destinationDir)
      }

      // Check if destination file already exists
      if filesManager.fileExists(destinationFile) {
        if overwrite {
          logger.warn("File \(destinationFile.lastComponent.string.quoted) already exists, overwriting...")
          try filesManager.delete(destinationFile)
        } else {
          logger.info("File \(destinationFile.lastComponent.string.quoted) already exists, skipping (overwrite=false)")
          continue
        }
      }

      // Copy the file
      logger.info("Copying \(sourceFile.lastComponent.string.quoted) to \(destinationFile.string.quoted)")

      do {
        try filesManager.copy(sourceFile, to: destinationFile)
        copiedFiles.append((source: sourceFile, destination: destinationFile))
        logger.debug("Successfully copied \(sourceFile.lastComponent.string.quoted)")
      } catch {
        logger.error("Failed to copy \(sourceFile.string.quoted) to \(destinationFile.string.quoted): \(error)")
        throw error
      }
    }

    logger.success("Successfully copied \(copiedFiles.count) files to \(targetDir.string.quoted)")
    return copiedFiles
  }
}
