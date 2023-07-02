//

import Foundation

import Simulator
import SwiftlaneCore
import Xcodebuild

public protocol TestRunPerforming {
    func runTests() throws -> [TestsRunner.TestRunResult]
}

extension MultiScan: TestRunPerforming {
    public func runTests() throws -> [TestsRunner.TestRunResult] {
        try self.run()
    }
}

extension Scan: TestRunPerforming {
    public func runTests() throws -> [TestsRunner.TestRunResult] {
        try [self.run()]
    }
}

public final class RunTestsTask {
    private let logger: Logging
    private let exitor: Exiting
    private let testRunPerformer: TestRunPerforming

    public init(
        logger: Logging,
        exitor: Exiting,
        testRunPerformer: TestRunPerforming
    ) {
        self.logger = logger
        self.exitor = exitor
        self.testRunPerformer = testRunPerformer
    }

    public func run() throws {
        let results = try testRunPerformer.runTests()

        let errors = results.compactMap(\.result.error)
        errors.forEach {
            logger.logError($0)
        }
        if let worstCode = errors.map(\.reason.rawValue).min() {
            exitor.exit(with: Int32(worstCode))
        }
        logger.success("RunTestsTask: Success.")
    }
}
