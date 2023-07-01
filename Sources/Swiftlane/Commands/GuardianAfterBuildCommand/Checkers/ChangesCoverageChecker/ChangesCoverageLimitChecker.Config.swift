//

import Foundation
import SwiftlaneCore

public extension ChangesCoverageLimitChecker {
    struct Config {
        public let decodableConfig: DecodableConfig
        public let projectDir: AbsolutePath
        public let excludedFileNameMatchers: [StringMatcher]
    }

    struct DecodableConfig: Decodable {
        /// Code coverage will not be checked for files which **paths** match any of given matchers.
        public let filesToIgnoreCheck: [StringMatcher]

        /// Percent of coverage of changed executable lines (0 - 100).
        public let changedLinesCoverageLimit: Int

        /// Do not check changes coverage when Merge Request Source Branch is one of these.
        public let ignoreCheckForSourceBranches: [StringMatcher]

        /// Do not check changes coverage when Merge Request Target Branch is one of these.
        public let ignoreCheckForTargetBranches: [StringMatcher]

        public init(
            filesToIgnoreCheck: [StringMatcher],
            changedLinesCoverageLimit: Int,
            ignoreCheckForSourceBranches: [StringMatcher],
            ignoreCheckForTargetBranches: [StringMatcher]
        ) {
            self.filesToIgnoreCheck = filesToIgnoreCheck
            self.changedLinesCoverageLimit = changedLinesCoverageLimit
            self.ignoreCheckForSourceBranches = ignoreCheckForSourceBranches
            self.ignoreCheckForTargetBranches = ignoreCheckForTargetBranches
        }
    }
}
