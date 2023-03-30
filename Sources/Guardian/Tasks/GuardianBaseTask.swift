//

import Foundation
import SwiftlaneCore

public final class GuardianCommonRunner: GuardianBaseTask {
    private var runnable: () throws -> Void = {}

    override public func executeChecksOnly() throws {
        try runnable()
    }

    public func run(_ runnable: @escaping () throws -> Void) throws {
        self.runnable = runnable
        try run()
    }
}

open class GuardianBaseTask {
    public enum Errors: Error {
        case executeChecksIsNotOverriden
    }

    private let reporter: MergeRequestReporting
    private let logger: Logging

    public init(
        reporter: MergeRequestReporting,
        logger: Logging
    ) {
        self.reporter = reporter
        self.logger = logger
    }

    public func run() throws {
        do {
            try executeChecksOnly()
        } catch let error as MergeRequestReporter.Errors {
            /// ignore errors produced by MergeRequestReporter
            /// because it means we are running ``GuardianBaseTask`` inside ``GuardianBaseTask``
            /// and report has already been published.
            logger.info("Look! We are running a GuardianBaseTask inside another GuardianBaseTask.")
            throw error
        } catch {
            let errorMessage = transformErrorToReportedFailMessage(error)
            reporter.fail(errorMessage)
            try? reporter.createOrUpdateReport()
            throw error
        }
        try reporter.createOrUpdateReport()
    }

    /// DO NOT CALL THIS DIRECTLY. Call `run()` instead.
    ///
    /// Override this and run any required checks.
    ///
    /// Use `reporter.fail` to report fails during checks,
    /// only throw error if something really bad or unexpected happens.
    open func executeChecksOnly() throws {
        throw Errors.executeChecksIsNotOverriden
    }

    /// Transform any catched error during running `executeChecks` into message
    /// which will be reported as a comment of merge request.
    open func transformErrorToReportedFailMessage(_ error: Error) -> String {
        "Guardian catched the error: \(error)"
    }
}
