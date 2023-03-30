//

import Foundation
import Simulator
import SwiftlaneCore
import Xcodebuild

public extension MultiScan {
    struct Config {
        public let builderConfig: Builder.Config
        public let testsRunnerConfig: TestsRunner.Config
        public let referenceSimulator: Simulator
        public let simulatorsCount: UInt
        public let resultsDir: AbsolutePath
        public let mergedXCResultPath: AbsolutePath
        public let mergedJUnitPath: AbsolutePath
    }
}
