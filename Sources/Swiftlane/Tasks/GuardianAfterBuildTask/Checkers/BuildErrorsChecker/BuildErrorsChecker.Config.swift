//

import Foundation
import SwiftlaneCore

public extension BuildErrorsChecker {
    struct Config {
        public let projectDir: AbsolutePath
        public let derivedDataPath: AbsolutePath
        public let htmlReportOutputDir: AbsolutePath
        public let jsonReportOutputFilePath: AbsolutePath
    }
}
