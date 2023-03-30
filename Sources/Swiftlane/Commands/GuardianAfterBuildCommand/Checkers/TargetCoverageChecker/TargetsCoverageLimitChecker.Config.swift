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
        static let defaultFilterSetName = "base"

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
