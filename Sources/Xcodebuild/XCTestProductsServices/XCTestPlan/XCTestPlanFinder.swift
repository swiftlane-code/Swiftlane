//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol XCTestPlanFinding {
    /// Find `.xctestplan` files in derived data through parsing `.xctestrun` plists.
    func findXCTestPlans(derivedDataPath: AbsolutePath) throws -> [AbsolutePath]
    /// Find `.xctestplan` files in `directory`.
    func findXCTestPlans(in directory: AbsolutePath) throws -> [AbsolutePath]
}

public class XCTestPlanFinder {
    private let filesManager: FSManaging
    private let xcTestRunFinder: XCTestRunFinding
    private let xcTestRunParser: XCTestRunParsing

    public init(
        filesManager: FSManaging,
        xctestRunFinder: XCTestRunFinding,
        xcTestRunParser: XCTestRunParsing
    ) {
        self.filesManager = filesManager
        xcTestRunFinder = xctestRunFinder
        self.xcTestRunParser = xcTestRunParser
    }
}

extension XCTestPlanFinder: XCTestPlanFinding {
    public func findXCTestPlans(derivedDataPath: AbsolutePath) throws -> [AbsolutePath] {
        let xcTestRunPath = try xcTestRunFinder.findXCTestRunFile(derivedDataPath: derivedDataPath)
        let xcTestPaths = try xcTestRunParser.parseXCTestPaths(xcTestRunPath: xcTestRunPath)

        let testPlansPaths = try xcTestPaths.flatMap {
            try findXCTestPlans(in: $0)
        }

        return testPlansPaths
    }

    public func findXCTestPlans(in directory: AbsolutePath) throws -> [AbsolutePath] {
        try filesManager.find(directory)
            .filter { $0.string.hasSuffix(".xctestplan") }
    }
}
