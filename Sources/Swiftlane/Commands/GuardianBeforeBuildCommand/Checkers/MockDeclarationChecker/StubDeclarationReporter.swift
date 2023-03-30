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
            "* **extension** для  `\($0.typeName)` из `\($0.typeDefinedIn)`, " +
            "этот экстеншен может быть в одном из таргетов: \(styleTargets($0.extensionMayBeIn))."
        }.joined(separator: "\n\n")
        let message = "`" + file + "`\n\n" + violationsMessage

        if config.fail {
            reporter.fail(message)
        } else {
            reporter.warn(message)
        }
    }

    public func reportExpiredToDoCheckerDisabled() {
        reporter.message("Проверка деклараций моков в соответствующих таргетах отключена.")
    }

    public func reportSuccessIfNeeded() {
        guard !reporter.hasFails() else {
            return
        }
        reporter.success("Проверка деклараций моков в соответствующих таргетах пройдена.")
    }
}

// swiftformat:enable indent
