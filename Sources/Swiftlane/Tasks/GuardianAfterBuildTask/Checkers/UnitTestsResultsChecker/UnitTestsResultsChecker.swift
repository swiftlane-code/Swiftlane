//

import Foundation
import Guardian
import SwiftlaneCore

// sourcery: AutoMockable
public protocol UnitTestsResultsChecking {
    func checkIfUnitTestsFailed() throws -> Bool
}

public class UnitTestsResultsChecker {
    private let junitService: JUnitServicing
    private let gitlabCIEnvironmentReader: GitLabCIEnvironmentReading
    private let reporter: UnitTestsResultsReporting
    private let config: Config

    public init(
        junitService: JUnitServicing,
        gitlabCIEnvironmentReader: GitLabCIEnvironmentReading,
        reporter: UnitTestsResultsReporting,
        config: Config
    ) {
        self.junitService = junitService
        self.gitlabCIEnvironmentReader = gitlabCIEnvironmentReader
        self.reporter = reporter
        self.config = config
    }

    public struct Failure: Equatable {
        public let failure: JUnitTestSuites.TestSuite.TestCase.Failure
        public let testCaseName: String
    }
}

extension UnitTestsResultsChecker: UnitTestsResultsChecking {
    public func checkIfUnitTestsFailed() throws -> Bool {
        let junit: JUnitTestSuites
        do {
            let junitPath = config.junitPath
            junit = try junitService.parseJUnit(filePath: junitPath)
        } catch {
            let jobUrl = try gitlabCIEnvironmentReader.string(.CI_JOB_URL)
            reporter.failedToParseJUnit(error: error, jobUrl: jobUrl)
            return true
        }

        let failures = junit.testsuite
            .flatMap(\.testcase)
            .flatMap { testCase in
                (testCase.failure ?? []).map {
                    Failure(failure: $0, testCaseName: testCase.name)
                }
            }

        guard !failures.isEmpty else {
            return false
        }

        reporter.failedUnitTestsDetected(failures)
        return true
    }
}
