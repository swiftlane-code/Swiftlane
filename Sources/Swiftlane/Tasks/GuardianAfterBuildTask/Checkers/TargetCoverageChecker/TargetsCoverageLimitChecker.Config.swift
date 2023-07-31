//

import Foundation
import SwiftlaneCore

public extension TargetsCoverageLimitChecker {
    struct Config {
        public let decodableConfig: DecodableConfig

        public let projectDir: AbsolutePath
        public let xcresultDir: AbsolutePath
        public let xccovTempCoverageFilePath: AbsolutePath
    }

    struct DecodableConfig: Decodable {
        /// Name of filters from ``excludeFilesFilters`` to be used for target by default.
        public static let defaultFilterSetName = "base"

        public var defaultFilters: [StringMatcher] {
            excludeFilesFilters?[Self.defaultFilterSetName] ?? []
        }

        /// Which files' coverage should NOT be considered.
        /// Dictionary with `<filters set name> : <matchers>`
        public let excludeFilesFilters: [String: [StringMatcher]]?

        /// Min percent of coverage for targets. Format: [<Target name>:<Coverage percent from 0 to 100>].
        public let targetCoverageLimits: [String: TargetSetting]

        /// Check only coverage of targets which product name has one of these suffixes.
        public let allowedProductNameSuffixes: [String]

        /// Do not check code coverage of targets with these names.
        public let excludeTargetsNames: [StringMatcher]
        
        /// This can be useful as for example GitLab can parse the number from job logs.
        /// If you set the value to `"GITLAB_PARSED_TOTAL_CODE_COVERAGE: "`
        /// then you can set the regex in GitLab settings to `GITLAB_PARSED_TOTAL_CODE_COVERAGE: (\d+.\d+)%`.
        /// Regex is configured in Gitlab Repo -> Settings -> CI/CD -> General Pipelines -> Test coverage parsing.
        ///
        /// Set this to `nil` to disable the total coverage message in logs.
        public let totalCodeCoverageMessagePrefix: String?

        public init(
            excludeFilesFilters: [String: [StringMatcher]]? = nil,
            targetCoverageLimits: [String: TargetsCoverageLimitChecker.DecodableConfig.TargetSetting],
            allowedProductNameSuffixes: [String],
            excludeTargetsNames: [StringMatcher],
            totalCodeCoverageMessagePrefix: String?
        ) {
            self.excludeFilesFilters = excludeFilesFilters
            self.targetCoverageLimits = targetCoverageLimits
            self.allowedProductNameSuffixes = allowedProductNameSuffixes
            self.excludeTargetsNames = excludeTargetsNames
            self.totalCodeCoverageMessagePrefix = totalCodeCoverageMessagePrefix
        }

        public struct TargetSetting: Decodable {
            public let limit: Int
            /// Names of filters sets.
            public let filtersSetsNames: [String]?

            public enum CodingKeys: CodingKey {
                case limit
                case filters
            }

            public init(limit: Int, filtersSetsNames: [String]?) {
                self.limit = limit
                self.filtersSetsNames = filtersSetsNames
            }

            /// Either decode `Int` or `limit: Int \n filter: [String]`.
            public init(from decoder: Decoder) throws {
                if let limit = try? decoder.singleValueContainer().decode(Int.self) {
                    self.limit = limit
                    filtersSetsNames = nil
                    return
                }

                let container = try decoder.container(keyedBy: CodingKeys.self)
                limit = try container.decode(Int.self, forKey: CodingKeys.limit)
                filtersSetsNames = try container.decodeIfPresent([String].self, forKey: CodingKeys.filters)
            }
        }
    }
}
