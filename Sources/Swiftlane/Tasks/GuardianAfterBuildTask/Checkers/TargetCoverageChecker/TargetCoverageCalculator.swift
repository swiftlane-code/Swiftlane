//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol TargetCoverageCalculating {
    func calculateTargetsCoverage(targets: [XCCOVTargetCoverage]) throws -> [CalculatedTargetCoverage]
}

public class TargetCoverageCalculator {
    public struct Config {
        public let defaultFilters: [StringMatcher]

        /// Which files' coverage should NOT be considered.
        /// Dictionary with `<filters set name> : <matchers>`
        public let excludeFilesFilters: [String: [StringMatcher]]?

        /// Min percent of coverage for targets.
        public let targetCoverageLimits: [String: TargetsCoverageLimitChecker.DecodableConfig.TargetSetting]

        public let projectDir: AbsolutePath
    }

    private let logger: Logging
    private let config: Config

    public init(logger: Logging, config: Config) {
        self.logger = logger
        self.config = config
    }
}

// swiftformat:disable indent
extension TargetCoverageCalculator: TargetCoverageCalculating {
	public func calculateTargetsCoverage(targets: [XCCOVTargetCoverage]) throws -> [CalculatedTargetCoverage] {
		let filterSets = config.excludeFilesFilters
		let defaultFilters = config.defaultFilters

		return try targets.compactMap { target -> CalculatedTargetCoverage? in
			let targetName = target.realTargetName
			let targetSettings = config.targetCoverageLimits[targetName]
			let explicitTargetFilters: [StringMatcher]? = try targetSettings?.filtersSetsNames?.flatMap {
				try filterSets?[$0].unwrap(
					errorDescription: "Filters set with name \($0.quoted) not specified in config."
				) ?? []
			}
			let targetFilters = explicitTargetFilters ?? defaultFilters

			let consideredFiles = target.files.filter {
				let relativePath = $0.path.replacingOccurrences(of: config.projectDir.string + "/", with: "")
				return !targetFilters.isMatching(string: relativePath)
			}
			logger.verbose(
				"Code coverage calculation for target \(targetName) includes next files:\n" +
				consideredFiles.map { "\t" + $0.path.lastPathComponent }.joined(separator: "\n")
			)
			let executableLines = consideredFiles.summarize(\.executableLines)
			let coveredLines = consideredFiles.summarize(\.coveredLines)
			let lineCoverage = executableLines > 0 ? Double(coveredLines) / Double(executableLines) : 1
			return CalculatedTargetCoverage(
			    targetName: target.realTargetName,
			    executableLines: executableLines,
			    coveredLines: coveredLines,
			    lineCoverage: lineCoverage,
			    limitInt: targetSettings?.limit
			)
		}
	}
}

// swiftformat:enable indent
