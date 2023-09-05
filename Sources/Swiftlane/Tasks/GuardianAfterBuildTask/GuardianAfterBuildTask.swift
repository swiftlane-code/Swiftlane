//

import Foundation
import Git
import Guardian
import SwiftlaneCore

public final class GuardianAfterBuildTask {
    // MARK: Services

    private let logger: Logging
    private let reporter: MergeRequestReporting
    private let environmentValueReader: EnvironmentValueReading

    // MARK: Checkers

    private let targetCoverageChecker: TargetsCoverageLimitChecking
    private let changesCoverageChecker: ChangesCoverageLimitChecking?
    private let buildErrorsChecker: BuildErrorsChecking
    private let buildWarningsChecker: BuildWarningsChecking
    private let unitTestsChecker: UnitTestsResultsChecking
    private let exitCodeChecker: UnitTestsExitCodeChecking

    private let config: Config

    public init(
        logger: Logging,
        mergeRequestReporter: MergeRequestReporting,
        targetCoverageChecker: TargetsCoverageLimitChecking,
        changesCoverageChecker: ChangesCoverageLimitChecking?,
        buildErrorsChecker: BuildErrorsChecking,
        buildWarningsChecker: BuildWarningsChecking,
        unitTestsChecker: UnitTestsResultsChecking,
        exitCodeChecker: UnitTestsExitCodeChecking,
        config: Config,
        environmentValueReader: EnvironmentValueReading
    ) {
        self.reporter = mergeRequestReporter
        self.logger = logger
        self.targetCoverageChecker = targetCoverageChecker
        self.changesCoverageChecker = changesCoverageChecker
        self.buildErrorsChecker = buildErrorsChecker
        self.buildWarningsChecker = buildWarningsChecker
        self.unitTestsChecker = unitTestsChecker
        self.exitCodeChecker = exitCodeChecker
        self.config = config
        self.environmentValueReader = environmentValueReader
    }

    /// Returns `true` if any error is found in build log.
    private func findBuildErrors() throws -> Bool {
        try buildErrorsChecker.generateReports()

        return try buildErrorsChecker.checkBuildErrors()
            || buildWarningsChecker.checkBuildWarnings()
    }

    private func findUnitTestsErrors() throws -> Bool {
        try unitTestsChecker.checkIfUnitTestsFailed()
    }

    private func validateTargetsCoverage() throws {
        try targetCoverageChecker.checkTargetsCodeCoverage()
    }

    private func validateChangesCoverage() throws {
        try changesCoverageChecker?.checkChangedFilesCoverageLimits()
    }

    public func run() throws {
        if try findBuildErrors() {
            // Do nothing more
        } else if try findUnitTestsErrors() {
            // Do nothing more
        } else if try exitCodeChecker.checkUnitTestsExitCode() {
            // Do nothing more
        } else {
            try validateChangesCoverage()
            try validateTargetsCoverage()
        }

        if !reporter.hasFails() {
            reporter.success("All checks passed!")
        }
    }
}
