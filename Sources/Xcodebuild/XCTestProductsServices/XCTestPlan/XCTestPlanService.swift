//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol XCTestPlanServicing {
    /// Searches for a test plan inside derived data.
    /// - Parameters:
    ///   - testPlanName: name of the test plan excluding `.xctestplan` extension.
    ///   - derivedDataPath: path build to derived data.
    /// - Returns: test plan info.
    func getTestPlan(
        named: String,
        inDerivedDataPath: AbsolutePath
    ) throws -> XCTestPlanInfo

    /// Searches for a test plan inside a directory (recursively).
    /// - Parameters:
    ///   - testPlanName: name of the test plan excluding `.xctestplan` extension.
    ///   - directory: where to search for the test plan file (recursively).
    /// - Returns: test plan info.
    func getTestPlan(
        named testPlanName: String,
        inDirectory directory: AbsolutePath
    ) throws -> XCTestPlanInfo

    /// Test plan may have either skippedTests array or selectedTests array.
    /// This method returns all built tests filtered to only include tests
    /// which should be run according to the specified test plan.
    /// - Parameters:
    ///   - builtTests: all built tests.
    ///   - xcTestPlan: test plan model.
    /// - Returns: `builtTests` fitlered according to the `xcTestPlan`.
    ///
    /// Notes:
    /// * Test name in test plan may include only class name and dont include concrete functions of the class.
    /// * Test name in test plan has `()` in the end of its name in case its a function.
    /// * Test names in `builtTests` are always functions and don't end with `()`.
    func filter(builtTests: [XCTestFunction], using: XCTestPlanInfo) -> [XCTestFunction]
}

public class XCTestPlanService {
    public enum Errors: Error, Equatable {
        case testPlanNotFound(testPlanName: String, derivedDataPath: String)
        case testPlanNotFound(testPlanName: String, searchedDirectory: String)
    }

    let testPlanFinder: XCTestPlanFinding
    let testPlanParser: XCTestPlanParsing

    public init(
        testPlanFinder: XCTestPlanFinding,
        testPlanParser: XCTestPlanParsing
    ) {
        self.testPlanFinder = testPlanFinder
        self.testPlanParser = testPlanParser
    }
}

extension XCTestPlanService: XCTestPlanServicing {
    /// Searches for a test plan inside derived data.
    /// - Parameters:
    ///   - testPlanName: name of the test plan excluding `.xctestplan` extension.
    ///   - derivedDataPath: path build to derived data.
    /// - Returns: test plan info.
    public func getTestPlan(
        named testPlanName: String,
        inDerivedDataPath derivedDataPath: AbsolutePath
    ) throws -> XCTestPlanInfo {
        let plans = try testPlanFinder
            .findXCTestPlans(derivedDataPath: derivedDataPath)
            .map(testPlanParser.parseTestPlan)

        guard
            let plan = plans.first(where: { $0.name == testPlanName })
        else {
            throw Errors.testPlanNotFound(testPlanName: testPlanName, derivedDataPath: derivedDataPath.string)
        }

        return plan
    }

    /// Searches for a test plan inside a directory (recursively).
    /// - Parameters:
    ///   - testPlanName: name of the test plan excluding `.xctestplan` extension.
    ///   - directory: where to search for the test plan file (recursively).
    /// - Returns: test plan info.
    public func getTestPlan(
        named testPlanName: String,
        inDirectory directory: AbsolutePath
    ) throws -> XCTestPlanInfo {
        let plans = try testPlanFinder
            .findXCTestPlans(in: directory)
            .map(testPlanParser.parseTestPlan)

        guard
            let plan = plans.first(where: { $0.name == testPlanName })
        else {
            throw Errors.testPlanNotFound(testPlanName: testPlanName, searchedDirectory: directory.string)
        }

        return plan
    }

    /// Test plan may have either skippedTests array or selectedTests array.
    /// This method returns all built tests filtered to only include tests
    /// which should be run according to the specified test plan.
    /// - Parameters:
    ///   - builtTests: all built tests.
    ///   - xcTestPlan: test plan model.
    /// - Returns: `builtTests` fitlered according to the `xcTestPlan`.
    ///
    /// Notes:
    /// * Test name in test plan may include only class name and dont include concrete functions of the class.
    /// * Test name in test plan has `()` in the end of its name in case its a function.
    /// * Test names in `builtTests` are always functions and don't end with `()`.
    public func filter(
        builtTests: [XCTestFunction],
        using xcTestPlan: XCTestPlanInfo
    ) -> [XCTestFunction] {
        func isTestMatchingOneInTestPlan(builtTestName: String, testPlanTests: [String]) -> Bool {
            testPlanTests.contains {
                // starts(with:) check for testPlan's test listed as "SMRunTests/PickupTest"
                // equals check for testPlan's test listed as "SMRunTests/PickupTest/test_that_smth()"
                builtTestName.starts(with: $0) || builtTestName + "()" == $0
            }
        }

        if !xcTestPlan.selectedTests.isEmpty {
            let filtered = builtTests.filter {
                isTestMatchingOneInTestPlan(builtTestName: $0.name, testPlanTests: xcTestPlan.selectedTests)
            }
            return filtered
        }

        if !xcTestPlan.skippedTests.isEmpty {
            let filtered = builtTests.filter {
                !isTestMatchingOneInTestPlan(builtTestName: $0.name, testPlanTests: xcTestPlan.skippedTests)
            }
            return filtered
        }

        return builtTests
    }
}
