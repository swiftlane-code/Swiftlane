//

import Foundation
import SwiftlaneCore

public extension GuardianAfterBuildTask {
    struct Config {
        public let projectDir: AbsolutePath
        public let buildErrorsCheckerConfig: BuildErrorsChecker.Config
        public let buildWarningsCheckerConfig: BuildWarningsChecker.Config
        public let unitTestsResultsCheckerConfig: UnitTestsResultsChecker.Config
        public let exitCodeCheckerConfig: UnitTestsExitCodeChecker.Config
        public let changesCoverageLimitCheckerConfig: ChangesCoverageLimitChecker.Config?
        public let targetsCoverageLimitCheckerConfig: TargetsCoverageLimitChecker.Config
    }
}
