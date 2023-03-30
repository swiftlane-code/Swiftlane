//

import Foundation
import SwiftlaneCore

public class PeripheryResultsMarkdownFormatter {
    private let filesManager: FSManaging

    public init(
        filesManager: FSManaging
    ) {
        self.filesManager = filesManager
    }

    private func readLineOfFile(file: AbsolutePath, line: UInt) throws -> String {
        let fileLines = try filesManager.readText(
            file,
            log: true
        ).split(separator: "\n", omittingEmptySubsequences: false)

        let lineIndex = Int(line) - 1
        let line = try fileLines[safe: lineIndex].unwrap(
            errorDescription: "Bad index \(lineIndex) for line in file \(file)"
        )

        return String(line)
    }

    private func format(result: PeripheryModels.ScanResult) throws -> String {
        let hint: String = {
            switch result.hints.annotation {
            case .unused:
                return "Unused"
            case .assignOnlyProperty:
                return "Property is never read"
            case .redundantProtocol:
                return "Redundant protocol"
            case .redundantPublicAccessibility:
                return "Redundant public accessibility"
            case .redundantConformance:
                return "Redundant conformance"
            }
        }()

        let codeLine = try readLineOfFile(file: result.location.file, line: result.location.line)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return "\(hint) \(result.kind.displayName ?? "") `\(result.name)` at line \(result.location.line).\n\n`\(codeLine)`"
    }
}

extension PeripheryResultsMarkdownFormatter: PeripheryResultsFormatting {
    public func format(results: [PeripheryModels.ScanResult]) throws -> String {
        try results.map(format(result:)).joined(separator: "\n\n___\n\n")
    }
}
