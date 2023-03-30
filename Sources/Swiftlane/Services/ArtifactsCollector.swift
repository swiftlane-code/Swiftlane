//

import Foundation
import SwiftlaneCore

public class ArtifactsCollector {
    public let filesManager: FSManaging
    public let logger: Logging

    public init(
        filesManager: FSManaging,
        logger: Logging
    ) {
        self.filesManager = filesManager
        self.logger = logger
    }

    public func collectArtifacts(dirs: [AbsolutePath], targetDir: AbsolutePath) throws {
        logger.verbose("Collecting artifacts: \(dirs)...")
        try? filesManager.delete(targetDir)
        try filesManager.mkdir(targetDir)

        try dirs.forEach { dir in
            let destination = targetDir.appending(path: dir.lastComponent)
            try filesManager.copy(dir, to: destination)
        }
    }
}
