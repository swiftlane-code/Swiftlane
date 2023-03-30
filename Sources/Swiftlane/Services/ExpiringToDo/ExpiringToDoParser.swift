//

import Foundation
import SwiftlaneCore

public protocol ExpiringToDoParsing {
    func parseToDos(
        from code: String,
        fileName: RelativePath
    ) throws -> [ParsedExpiringToDoModel]
}

public class ExpiringToDoParser {
    public enum Errors: Error {
        case invalidRegexGroupsCount(regex: String, expectedGroupsCount: Int)
    }

    ///	TODO line regex.
    ///
    /// Matches something like:
    /// * `// TODO: [anything] @no.spaces Do something`
    /// * `// TODO: [anything] Do something`
    private let regex = try! NSRegularExpression(
        pattern: #"\/\/ *TODO:? *\[(.*)] *(?:@(\S*))? *(.*)$"#,
        options: .anchorsMatchLines
    )
}

extension ExpiringToDoParser: ExpiringToDoParsing {
    public func parseToDos(
        from code: String,
        fileName: RelativePath
    ) throws -> [ParsedExpiringToDoModel] {
        let expectedRegexGroupsCount = 3
        guard regex.numberOfCaptureGroups == expectedRegexGroupsCount else {
            throw Errors.invalidRegexGroupsCount(regex: regex.pattern, expectedGroupsCount: expectedRegexGroupsCount)
        }

        let lines = code.split(separator: "\n", omittingEmptySubsequences: false)

        return lines.enumerated().flatMap { lineIndex, line in
            regex.matchesGroups(in: String(line)).map { groups in
                // let todoText = groups[3]
                ParsedExpiringToDoModel(
                    file: fileName,
                    line: UInt(lineIndex + 1),
                    fullMatch: String(groups[0]),
                    author: String(groups[2]).nilIfEmpty,
                    dateString: String(groups[1])
                )
            }
        }
    }
}
