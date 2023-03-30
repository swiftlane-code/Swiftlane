//

import Foundation

// sourcery: AutoMockable
public protocol UnitTestsResultsReporting {
    func failedToParseJUnit(error: Error, jobUrl: String)
    func failedUnitTestsDetected(_ failures: [UnitTestsResultsChecker.Failure])
}
