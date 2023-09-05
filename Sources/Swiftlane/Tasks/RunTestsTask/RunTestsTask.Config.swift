//

import Foundation
import SwiftlaneCore

public extension RunTestsTask {
    struct Config {
        public let projectDir: AbsolutePath
        public let projectFile: AbsolutePath
        public let scheme: String
        public let deviceModel: String
        public let osVersion: String
        public let simulatorsCount: UInt
        public let testPlan: String?
        public let derivedDataDir: AbsolutePath
        public let testRunsDerivedDataDir: AbsolutePath
        public let logsDir: AbsolutePath
        public let resultsDir: AbsolutePath
        public let mergedXCResultPath: AbsolutePath
        public let mergedJUnitPath: AbsolutePath
        public let testWithoutBuilding: Bool
        public let useMultiScan: Bool
        public let xcodebuildFormatterCommand: String
        public let testingTimeout: TimeInterval
    }
}
