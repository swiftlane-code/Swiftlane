//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol BuildErrorsChecking {
    /// Generates needed reports
    func generateReports() throws
    /// Returns `true` if any error is found in build log.
    func checkBuildErrors() throws -> Bool
}

public class BuildErrorsChecker {
    private let xclogparser: XCLogParserServicing
    private let reporter: BuildErrorsReporting
    private let logger: Logging
    let config: Config

    public init(
        xclogparser: XCLogParserServicing,
        reporter: BuildErrorsReporting,
        logger: Logging,
        config: Config
    ) {
        self.xclogparser = xclogparser
        self.reporter = reporter
        self.logger = logger
        self.config = config
    }
}

extension BuildErrorsChecker: BuildErrorsChecking {
    public func generateReports() throws {
        logger.info("Generate HTML report from xclogparser...")
        try xclogparser.generateReportHTML(
            derivedDataPath: config.derivedDataPath,
            outputDirPath: config.htmlReportOutputDir
        )

        logger.info("Generate issues report from xclogparser...")
        try xclogparser.generateReportIssues(
            derivedDataPath: config.derivedDataPath,
            outputFilePath: config.jsonReportOutputFilePath
        )
    }

    public func checkBuildErrors() throws -> Bool {
        logger.info("Check builds errors...")
        let report = try xclogparser.readXCLogParserReport(
            reportPath: config.jsonReportOutputFilePath
        )

        let errors = report.errors

        guard !errors.isEmpty else {
            return false
        }
        reporter.report(errors: errors, projectDir: config.projectDir)
        return true
    }
}
