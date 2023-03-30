//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol BuildWarningsChecking {
    /// Generates needed reports
    func generateReport() throws
    /// Returns `true` if any warning is found in build log.
    func checkBuildWarnings() throws -> Bool
}

public extension BuildWarningsChecker {
    struct Config {
        public let projectDir: AbsolutePath
        public let derivedDataPath: AbsolutePath
        public let jsonReportOutputFilePath: AbsolutePath
        public let decodableConfig: DecodableConfig
    }

    struct DecodableConfig: Codable {
        public let failBuildWhenWarningsDetected: Bool
        public let ignoreWarningTitle: [StringMatcher]
        public let ignoreWarningLocation: [StringMatcher]
        public let ignoreWarningType: [StringMatcher]
    }
}

public class BuildWarningsChecker {
    private let xclogparser: XCLogParserServicing
    private let reporter: BuildWarningsReporting
    private let logger: Logging
    public let config: Config

    public init(
        xclogparser: XCLogParserServicing,
        reporter: BuildWarningsReporting,
        logger: Logging,
        config: Config
    ) {
        self.xclogparser = xclogparser
        self.reporter = reporter
        self.logger = logger
        self.config = config
    }
}

extension BuildWarningsChecker: BuildWarningsChecking {
    public func generateReport() throws {
        logger.info("Generate issues report from xclogparser...")
        try xclogparser.generateReportIssues(
            derivedDataPath: config.derivedDataPath,
            outputFilePath: config.jsonReportOutputFilePath
        )
    }

    public func checkBuildWarnings() throws -> Bool {
        logger.info("Check builds warnings...")
        let report = try xclogparser.readXCLogParserReport(
            reportPath: config.jsonReportOutputFilePath
        )

        let warnings = report.warnings

        let filteredWarnings = try warnings.filter {
            let config = config.decodableConfig
            let warningJSON = $0.asPrettyJSON().lightYellow

            if let relativePath = try $0.documentPath?.relative(to: self.config.projectDir),
               config.ignoreWarningLocation.isMatching(string: relativePath.string)
            {
                logger.important("Ignored build warning because of 'ignoreWarningLocation' rules: \(warningJSON)")
                return false // drop from array
            }

            if config.ignoreWarningType.isMatching(string: $0.type.rawValue.uppercasedFirst) {
                logger.important("Ignored build warning because of 'ignoreWarningType' rules: \(warningJSON)")
                return false
            }

            if config.ignoreWarningTitle.isMatching(string: $0.title) {
                logger.important("Ignored build warning because of 'ignoreWarningTitle' rules: \(warningJSON)")
                return false
            }

            return true
        }

        logger.important("Total warnings: \(warnings.count)")
        logger.important("Filtered warnings: \(filteredWarnings.count)")
        logger.verbose(filteredWarnings.map { $0.asPrettyJSON().lightYellow }.joined(separator: "\n\n"))

        guard !filteredWarnings.isEmpty else {
            logger.success("No severe build warnings detected.")
            reporter.reportNoWarningsDetected()
            return false
        }
        reporter.report(warnings: filteredWarnings, projectDir: config.projectDir)
        return true
    }
}
