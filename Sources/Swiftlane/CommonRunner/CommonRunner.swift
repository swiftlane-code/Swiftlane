//

import Foundation
import GitLabAPI
import Guardian
import SwiftlaneCore

/// Allows to run any throwing closure.
///
/// When it catches an error it will log the error and exit with nonzero exit code.
public class CommonRunner {
    private let logger: Logging
    private let exitor: Exiting

    public init(
        logger: Logging,
        exitor: Exiting = Exitor()
    ) {
        self.logger = logger
        self.exitor = exitor
    }

    private func makeGuardianRunnerIfPossible() -> GuardianCommonRunner? {
        do {
            let mergeRequestReporter: MergeRequestReporting = DependenciesFactory.resolve()

            try (mergeRequestReporter as? GitLabMergeRequestReporter)?.checkEnvironmentCorrect()

            logger.success("Running under Guardian.")
            return GuardianCommonRunner(reporter: mergeRequestReporter, logger: logger)
        } catch {
            logger.warn("Running under Guardian is not possible (\(error)).")
            return nil
        }
    }

    public func run(_ closure: @escaping () throws -> Void) {
        do {
            if let guardian = makeGuardianRunnerIfPossible() {
                try guardian.run(closure)
            } else {
                try closure()
            }
        } catch {
            logger.logError(error)
            exitor.exit(with: 1)
        }
    }
}
