//

import Foundation
import SwiftlaneCore

public protocol GitDiffParsing {
    func parseGitDiff(_ diff: String, ignoreFormatErrors: Bool) throws -> [GitDiffParser.FileDiff]

    func changedLinesCount(in gitDiff: String) -> (added: Int, deleted: Int)
}

public class GitDiffParser: GitDiffParsing {
    public enum Errors: Error, CustomStringConvertible {
        case unexpectedBehaviour(String? = nil)

        public var description: String {
            let commonMessage = "Looks like either an error exists in parsing algorithm or parsed diff is invalid."
            switch self {
            case let .unexpectedBehaviour(description):
                return description.map { commonMessage + " " + $0 } ?? commonMessage
            }
        }
    }

    public struct FileDiff: Codable, Equatable {
        public let oldPath: RelativePath?
        public let newPath: RelativePath?
        public let diffType: FileDiffType
        public let oldFileMode: String?
        public let newFileMode: String?

        /// Array of line numbers which were added.
        /// Human-friendly line number starts from 1.
        /// This is the line number in the final file after applying changes.
        public let addedLineNumbers: [UInt]

        /// Array of line numbers which were deleted.
        /// Human-friendly line number starts from 1.
        /// This is the line number in old file before applying changes.
        public let deletedLineNumbers: [UInt]

        public enum FileDiffType: Codable, Equatable {
            case created
            case changed
            case deleted
        }
    }

    private let logger: Logging

    public init(logger: Logging) {
        self.logger = logger
    }

    public func parseGitDiff(_ diff: String, ignoreFormatErrors: Bool) throws -> [FileDiff] {
        let lines = diff.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)

        let diffLineNumbersRegex = try NSRegularExpression(
            pattern: #"^@@\ -([0-9]+)(?:,[0-9]+)?\ \+([0-9]+)(?:,[0-9]+)?\ @@.*"#
        )

        let diffChangedFilePathRegex = try NSRegularExpression(
            pattern: #"^diff --git (a\/.+) (b\/.+)$"#
        )

        let binaryFilesDifferPathsRegex = try NSRegularExpression(
            pattern: #"^Binary files (.+) and (.+) differ$"#
        )

        var oldPath: RelativePath?
        var newPath: RelativePath?
        var oldLineNumber: UInt?
        var newLineNumber: UInt?
        var oldFileMode: String?
        var newFileMode: String?
        var addedLineNumbers: [UInt] = []
        var deletedLineNumbers: [UInt] = []

        var results: [FileDiff] = []

        func parsePath<T: StringProtocol>(from string: T) throws -> RelativePath? {
            if string == "/dev/null" { return nil }
            return try RelativePath(string.dropFirst(2))
        }

        func finishDiffHunkParsing() {
            // another file changes are starting here
            if oldPath != nil || newPath != nil {
                let diffType: FileDiff.FileDiffType
                if oldPath == nil {
                    diffType = .created
                } else if newPath == nil {
                    diffType = .deleted
                } else {
                    //					diffType = oldPath == newPath ? .changed : .renamed
                    diffType = .changed
                }

                results.append(
                    FileDiff(
                        oldPath: oldPath,
                        newPath: newPath,
                        diffType: diffType,
                        oldFileMode: oldFileMode,
                        newFileMode: newFileMode,
                        addedLineNumbers: addedLineNumbers,
                        deletedLineNumbers: deletedLineNumbers
                    )
                )
            }

            oldPath = nil
            newPath = nil
            oldLineNumber = nil
            newLineNumber = nil
            oldFileMode = nil
            newFileMode = nil
            addedLineNumbers = []
            deletedLineNumbers = []
        }

        for line in lines {
            let firstWord = line.split(separator: " ", omittingEmptySubsequences: false).first

            switch firstWord {
            case "diff":
                /// Existance of line starting with `diff --git` is guarantied at the begginning of a diff hunk.
                finishDiffHunkParsing()
                if let groups = diffChangedFilePathRegex.firstMatchGroups(in: String(line)) {
                    /// This parsing method is not ideal because there is no way
                    /// to correctly parse something like this:
                    /// `diff --git a/ a/ b/a b/ a/ b/ b/b`.
                    ///
                    /// So we have additional parsing of consecutive (most probably existing) lines:
                    /// `--- a/ a/ b/a` and
                    /// `+++ b/ a/ b/ b/b`.
                    oldPath = try parsePath(from: groups[1])
                    newPath = try parsePath(from: groups[2])
                }

            case "---":
                /// Note: Line like `--- a/ a/ b/a` may not be present in a diff hunk.
                /// May be `--- /dev/null` without `a/`.
                oldPath = try parsePath(from: line.dropFirst(4)) /// drop `"--- "`

            case "+++":
                /// Note: Line like `+++ b/ a/ b/ b/b` may not be present in a diff hunk.
                /// /// May be `--- /dev/null` without `b/`.
                newPath = try parsePath(from: line.dropFirst(4)) /// drop `"--- "`

            case "old", "deleted":
                if line.starts(with: "old mode") || line.starts(with: "deleted file mode") {
                    oldFileMode = String(line.drop { !$0.isNumber })
                }

            case "new":
                if line.starts(with: "new mode ") || line.starts(with: "new file mode ") {
                    newFileMode = String(line.drop { !$0.isNumber })
                }

            case "similarity":
                break

            case "index":
                break

            case "rename":
                break

            case "\\":
                if line == "\\ No newline at end of file" {
                    // nothing to do.
                } else {
                    throw Errors.unexpectedBehaviour("unexpected diff line: \(String(line).quoted)")
                }

            case "Binary":
                if let groups = binaryFilesDifferPathsRegex.firstMatchGroups(in: String(line)) {
                    oldPath = try parsePath(from: groups[1])
                    newPath = try parsePath(from: groups[2])
                } else {
                    throw Errors.unexpectedBehaviour("unexpected diff line: \(String(line).quoted)")
                }

            default:
                if let groups = diffLineNumbersRegex.firstMatchGroups(in: String(line)) {
                    oldLineNumber = UInt(groups[1])
                    newLineNumber = UInt(groups[2])
                    continue
                }

                switch line.first {
                case " ", .none:
                    oldLineNumber.map { oldLineNumber = $0 + 1 }
                    newLineNumber.map { newLineNumber = $0 + 1 }
                case "+":
                    let lineNumber = try newLineNumber.unwrap(nilError: Errors.unexpectedBehaviour("newLineNumber is nil"))
                    try assert(lineNumber != 0, orThrow: Errors.unexpectedBehaviour("newLineNumber is 0"))
                    addedLineNumbers.append(lineNumber)
                    newLineNumber.map { newLineNumber = $0 + 1 }
                case "-":
                    let lineNumber = try oldLineNumber.unwrap(nilError: Errors.unexpectedBehaviour("oldLineNumber is nil"))
                    try assert(lineNumber != 0, orThrow: Errors.unexpectedBehaviour("oldLineNumber is 0"))
                    deletedLineNumbers.append(lineNumber)
                    oldLineNumber.map { oldLineNumber = $0 + 1 }
                default:
                    if ignoreFormatErrors {
                        logger.warn([
                            "encountered unexpected diff line",
                            newLineNumber?.description,
                            "in file ",
                            (newPath ?? oldPath)?.string,
                        ].compactMap { $0 }.joined(separator: " "))
                    } else {
                        throw Errors.unexpectedBehaviour("unexpected diff line: \(String(line).quoted)")
                    }
                }
            }
        }

        finishDiffHunkParsing()

        return results
    }

    public func changedLinesCount(in gitDiff: String) -> (added: Int, deleted: Int) {
        let lines = gitDiff.split(whereSeparator: \.isNewline)
        return (
            added: lines.lazy.filter { $0.starts(with: "+") }.count,
            deleted: lines.lazy.filter { $0.starts(with: "-") }.count
        )
    }
}
