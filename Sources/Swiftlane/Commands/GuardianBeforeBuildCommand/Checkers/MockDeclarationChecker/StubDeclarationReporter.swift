//

import Foundation
import Guardian
import SwiftlaneCore

// sourcery: AutoMockable
public protocol StubDeclarationReporting {
    func reportViolation(file: String, violations: [StubDeclarationViolation])

    func reportExpiredToDoCheckerDisabled()
    func reportSuccessIfNeeded()
}

public final class StubDeclarationReporter {
    private let reporter: MergeRequestReporting
    private let config: StubDeclarationConfig

    public init(
        reporter: MergeRequestReporting,
        config: StubDeclarationConfig
    ) {
        self.reporter = reporter
        self.config = config
    }
}

// swiftformat:disable indent
extension StubDeclarationReporter: StubDeclarationReporting {
    public func reportViolation(file: String, violations: [StubDeclarationViolation]) {
        func styleTargets(_ targetNames: [String]) -> String {
            targetNames.map { "`\($0)`" }.joined(separator: ", ")
        }

        let violationsMessage = violations.map {
            "* **extension** for type `\($0.typeName)` defined in `\($0.typeDefinedIn)`, " +
            "allowed targets for such extension: \(styleTargets($0.extensionMayBeIn))."
        }.joined(separator: "\n\n")
        let message = "`" + file + "`\n\n" + violationsMessage

        if config.fail {
            reporter.fail(message)
        } else {
            reporter.warn(message)
        }
    }

    public func reportExpiredToDoCheckerDisabled() {
        reporter.message("Check for mocks' extensension declaration places is disabled.")
    }

    public func reportSuccessIfNeeded() {
        guard !reporter.hasFails() else {
            return
        }
        reporter.success("Check for mocks' extensension declaration places has passed.")
    }
}

// swiftformat:enable indent
