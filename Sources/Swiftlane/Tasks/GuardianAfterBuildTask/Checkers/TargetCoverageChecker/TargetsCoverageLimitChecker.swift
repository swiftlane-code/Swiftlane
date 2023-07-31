//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol TargetsCoverageLimitChecking {
    func checkTargetsCodeCoverage() throws
}

public struct CalculatedTargetCoverage: Equatable {
    public let targetName: String
    public let executableLines: Int
    public let coveredLines: Int
    public let lineCoverage: Double
    public let limitInt: Int?
}

public class TargetsCoverageLimitChecker {
    public struct Violation: Equatable {
        public let targetName: String
        public let minCoverage: Double
        public let actualCoverage: Double
    }

    private let logger: Logging
    private let filesManager: FSManaging
    private let shell: ShellExecuting
    private let xccov: XCCOVServicing
    private let targetsFilterer: TargetsCoverageTargetsFiltering
    private let coverageCalculator: TargetCoverageCalculating
    private let reporter: TargetCoverageReporting

    private let config: Config

    public init(
        logger: Logging,
        filesManager: FSManaging,
        shell: ShellExecuting,
        xccov: XCCOVServicing,
        targetsFilterer: TargetsCoverageTargetsFiltering,
        coverageCalculator: TargetCoverageCalculating,
        reporter: TargetCoverageReporting,
        config: Config
    ) {
        self.logger = logger
        self.filesManager = filesManager
        self.shell = shell
        self.xccov = xccov
        self.targetsFilterer = targetsFilterer
        self.coverageCalculator = coverageCalculator
        self.reporter = reporter
        self.config = config
    }

    // MARK: - Generate and parse coverage JSON

    private func findXCResultFile() throws -> AbsolutePath {
        try filesManager.find(config.xcresultDir)
            .first(where: { $0.hasSuffix(".xcresult") })
            .unwrap(errorDescription: "Unable to find .xcresult under \"\(config.xcresultDir)\"")
    }

    // MARK: - Check targets coverage limits

    private func checkTargetsCoverageLimits(targets: [CalculatedTargetCoverage]) {
        let violations: [Violation] = targets
            .compactMap { target in
                guard let minPercent = target.limitInt else {
                    return nil
                }
                let minLineCoverage = Double(minPercent) / 100
                if target.lineCoverage < minLineCoverage {
                    return .init(
                        targetName: target.targetName,
                        minCoverage: minLineCoverage,
                        actualCoverage: target.lineCoverage
                    )
                }
                return nil
            }

        if violations.isEmpty {
            reporter.reportCoverageLimitsSuccess()
            return
        }

        violations.forEach {
            reporter.reportCoverageLimitsCheckFailed(violation: $0)
        }
    }

    // MARK: - Report total code base coverage

    /// 0 to 1
    private func calcTotalCoverage(targets: [CalculatedTargetCoverage]) -> Double {
        let totalExecutableLines = targets.reduce(0) { $0 + $1.executableLines }
        let totalCoveredLines = targets.reduce(0) { $0 + $1.coveredLines }
        return totalExecutableLines != 0
            ? Double(totalCoveredLines) / Double(totalExecutableLines)
            : 0
    }

    private func printTotalCoverage(targets: [CalculatedTargetCoverage]) {
        guard let prefix = config.decodableConfig.totalCodeCoverageMessagePrefix else {
            return
        }
        logger.log(.important, prefix + "\(calcTotalCoverage(targets: targets) * 100)%")
    }
}

extension TargetsCoverageLimitChecker: TargetsCoverageLimitChecking {
    public func checkTargetsCodeCoverage() throws {
        let xcresultPath = try findXCResultFile()

        let report = try xccov.generateAndParseCoverageReport(
            xcresultPath: xcresultPath,
            generatedCoverageFilePath: config.xccovTempCoverageFilePath
        )

        let targets = targetsFilterer.filterTargets(
            report: report,
            allowedProductNameSuffixes: config.decodableConfig.allowedProductNameSuffixes,
            excludeTargetsNames: config.decodableConfig.excludeTargetsNames
        )

        let processed = try coverageCalculator.calculateTargetsCoverage(targets: targets)
        checkTargetsCoverageLimits(targets: processed)
        reporter.reportAllTargetsCoverage(targets: processed)
        printTotalCoverage(targets: processed)
    }
}
