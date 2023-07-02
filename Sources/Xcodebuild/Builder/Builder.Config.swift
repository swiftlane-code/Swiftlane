//

import Foundation
import SwiftlaneCore

public extension Builder {
    struct Config {
        public let project: AbsolutePath
        public let scheme: String
        public let derivedDataPath: AbsolutePath
        public let logsPath: AbsolutePath
        public let configuration: String
        public let xcodebuildFormatterCommand: String

        /// Xcodebuild `build` or `build-for-testing` configuration.
        /// - Parameters:
        ///   - project: Path to .xcodeproj file.
        ///   - scheme: Scheme to build.
        ///   - derivedDataPath: Derived data path.
        ///   - logsPath: Path to directory where build logs will be stored.
        ///   - configuration: Build configuration name (usually `Debug` or `Release`)
        public init(
            project: AbsolutePath,
            scheme: String,
            derivedDataPath: AbsolutePath,
            logsPath: AbsolutePath,
            configuration: String,
            xcodebuildFormatterCommand: String
        ) {
            self.project = project
            self.scheme = scheme
            self.derivedDataPath = derivedDataPath
            self.logsPath = logsPath
            self.configuration = configuration
            self.xcodebuildFormatterCommand = xcodebuildFormatterCommand
        }
    }
}
