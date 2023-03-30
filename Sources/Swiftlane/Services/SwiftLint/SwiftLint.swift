//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol SwiftLintProtocol {
    func lint(
        swiftlintConfigPath: AbsolutePath,
        directory: String,
        projectDir: AbsolutePath
    ) throws -> [SwiftLintViolation]
}

public struct SwiftLintViolation: Encodable, Decodable, Hashable, Equatable {
    public enum Severity: String, Encodable, Decodable, Hashable, Equatable {
        case warning = "Warning"
        case error = "Error"
    }

    public let ruleID: String
    public let reason: String
    public let line: Int
    public let severity: Severity
    public let file: String

    public var messageText: String {
        reason + " (`\(ruleID)`)"
    }

    public enum CodingKeys: String, CodingKey {
        case ruleID = "rule_id"
        case reason, line, file, severity
    }
}

/// Custom swiftlint runner which doesn't expose linting results to final danger report.
public class SwiftLint: SwiftLintProtocol {
    public enum Errors: Error {
        case swiftLintFailed(stdout: String?, stderr: String?)
    }

    private let shell: ShellExecuting
    private let swiftlintPath: String

    public init(
        shell: ShellExecuting,
        swiftlintPath: String
    ) {
        self.shell = shell
        self.swiftlintPath = swiftlintPath
    }

    public func lint(
        swiftlintConfigPath: AbsolutePath,
        directory: String,
        projectDir: AbsolutePath
    ) throws -> [SwiftLintViolation] {
        let output: ShellOutput
        do {
            output = try shell.run(
                [
                    "cd \(projectDir) &&",
                    swiftlintPath,
                    "--reporter json",
                    "--quiet",
                    // Full path to config is required because of swiftlint bug.
                    "--config \(swiftlintConfigPath)",
                    "\(directory)",
                ].joined(separator: " "),
                log: .commandOnly
            )
        } catch let ShError.nonZeroExitCode(_, _output, _) {
            output = _output
        }

        if let violations = output.stdoutText.flatMap({ makeViolations(from: $0, projectDir: projectDir) }) {
            return violations
        } else if let stderr = output.stderrText, stderr.contains("No lintable files found at paths") {
            return []
        } else {
            throw Errors.swiftLintFailed(stdout: output.stdoutText, stderr: output.stderrText)
        }
    }

    private func makeViolations(from response: String, projectDir: AbsolutePath) -> [SwiftLintViolation]? {
        let decoder = JSONDecoder()
        let violations = try? decoder.decode(
            [SwiftLintViolation].self,
            from: Data(response.utf8)
        )

        return violations.map {
            $0.map {
                .init(
                    ruleID: $0.ruleID,
                    reason: $0.reason,
                    line: $0.line,
                    severity: $0.severity,
                    file: $0.file.replacingOccurrences(of: projectDir.string + "/", with: "")
                )
            }
        }
    }
}
