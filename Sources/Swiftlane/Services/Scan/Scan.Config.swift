//

import Foundation
import Simulator
import SwiftlaneCore

public extension Scan {
    struct Config {
        public let referenceSimulator: Simulator
        public let resultsDir: AbsolutePath
        public let logsPath: AbsolutePath
        public let scheme: String
        public let mergedXCResultPath: AbsolutePath
        public let mergedJUnitPath: AbsolutePath
    }
}
