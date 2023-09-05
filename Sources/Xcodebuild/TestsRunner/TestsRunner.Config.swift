//

import Foundation
import SwiftlaneCore

public extension TestsRunner {
    struct Config {
        public let project: AbsolutePath
        public let projectDirPath: AbsolutePath
        public let scheme: String
        public let buildDerivedDataPath: AbsolutePath
        public let testRunsDerivedDataPath: AbsolutePath
        public let testRunsLogsPath: AbsolutePath
        public let testPlan: String?
        public let testWithoutBuilding: Bool
        public let xcodebuildFormatterCommand: String
        public let testingTimeout: TimeInterval

        public init(
            builderConfig: Builder.Config,
            projectDirPath: AbsolutePath,
            testRunsDerivedDataPath: AbsolutePath,
            testRunsLogsPath: AbsolutePath,
            testPlan: String?,
            testWithoutBuilding: Bool,
            xcodebuildFormatterCommand: String,
            testingTimeout: TimeInterval
        ) {
            project = builderConfig.project
            self.projectDirPath = projectDirPath
            scheme = builderConfig.scheme
            buildDerivedDataPath = builderConfig.derivedDataPath
            self.testRunsDerivedDataPath = testRunsDerivedDataPath
            self.testRunsLogsPath = testRunsLogsPath
            self.testPlan = testPlan
            self.testWithoutBuilding = testWithoutBuilding
            self.xcodebuildFormatterCommand = xcodebuildFormatterCommand
            self.testingTimeout = testingTimeout
        }
    }
}
