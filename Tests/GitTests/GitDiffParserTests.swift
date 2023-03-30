//

import Foundation
import SwiftlaneCore
import SwiftlaneCoreMocks
import SwiftlaneUnitTestTools
import XCTest

@testable import Git

class GitDiffParserTests: XCTestCase {
    private func check(
        diffName: String,
        expectedResult: [GitDiffParser.FileDiff],
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        // given
        let logger = LoggingMock()
        logger.given(.logLevel(getter: .verbose))
        let parser = GitDiffParser(logger: logger)
        let diff = try Bundle.module.readStubText(path: "diffs/\(diffName).diff")

        // when
        let results = try parser.parseGitDiff(diff, ignoreFormatErrors: false)

        // then
        print(diff) // debug
        print("\nResults:")
        dump(results) // debug
        print("\nExpected:")
        dump(expectedResult)

        XCTAssertEqual(
            results.count,
            expectedResult.count,
            "Count of files in diff is not equal to expected.",
            file: file,
            line: line
        )
        zip(results, expectedResult).enumerated().forEach { idx, pair in
            let result = pair.0
            let expectedResult = pair.1
            XCTAssertEqual(result, expectedResult, "File diff at index \(idx) is not equal to expected.", file: file, line: line)
        }
    }

    func test_newFile() throws {
        try check(diffName: "newFileTrickyName", expectedResult: [
            GitDiffParser.FileDiff(
                oldPath: nil,
                newPath: try RelativePath(" a/ b/nice"),
                diffType: .created,
                oldFileMode: nil,
                newFileMode: "100644",
                addedLineNumbers: [1],
                deletedLineNumbers: []
            ),
        ])
    }

    func test_changedOneLine() throws {
        try check(diffName: "changedOneLine", expectedResult: [
            GitDiffParser.FileDiff(
                oldPath: try RelativePath("wear/recently/spring/minute/thousand/arrive.sh"),
                newPath: try RelativePath("wear/recently/spring/minute/thousand/arrive.sh"),
                diffType: .changed,
                oldFileMode: nil,
                newFileMode: nil,
                addedLineNumbers: [19],
                deletedLineNumbers: [19]
            ),
        ])
    }

    func test_changedOneLine_and_addedOneLine() throws {
        try check(diffName: "changedOneLine_and_addedOneLine", expectedResult: [
            GitDiffParser.FileDiff(
                oldPath: try RelativePath("scripts/some_script.sh"),
                newPath: try RelativePath("scripts/some_script.sh"),
                diffType: .changed,
                oldFileMode: nil,
                newFileMode: nil,
                addedLineNumbers: [6, 23],
                deletedLineNumbers: [22]
            ),
        ])
    }

    func test_deletedFile() throws {
        try check(diffName: "deletedFile", expectedResult: [
            GitDiffParser.FileDiff(
                oldPath: try RelativePath("ADTarget/Info.plist"),
                newPath: nil,
                diffType: .deleted,
                oldFileMode: "100644",
                newFileMode: nil,
                addedLineNumbers: [],
                deletedLineNumbers: (1 ... 22).map { $0 }
            ),
        ])
    }

    func test_changedModeOfFile() throws {
        try check(diffName: "chmod", expectedResult: [
            GitDiffParser.FileDiff(
                oldPath: try RelativePath("Utils/rclone.conf"),
                newPath: try RelativePath("Utils/rclone.conf"),
                diffType: .changed,
                oldFileMode: "100644",
                newFileMode: "100755",
                addedLineNumbers: [],
                deletedLineNumbers: []
            ),
        ])
    }

    func test_newFile2() throws {
        try check(diffName: "newFile2", expectedResult: [
            GitDiffParser.FileDiff(
                oldPath: nil,
                newPath: try RelativePath("b"),
                diffType: .created,
                oldFileMode: nil,
                newFileMode: "100644",
                addedLineNumbers: [1],
                deletedLineNumbers: []
            ),
        ])
    }

    func test_newFileOneLine() throws {
        try check(diffName: "newFileOneLine", expectedResult: [
            GitDiffParser.FileDiff(
                oldPath: nil,
                newPath: try RelativePath("new_file"),
                diffType: .created,
                oldFileMode: nil,
                newFileMode: "100644",
                addedLineNumbers: [1],
                deletedLineNumbers: []
            ),
        ])
    }

    func test_newEmptyFile() throws {
        try check(diffName: "newEmptyFile", expectedResult: [
            GitDiffParser.FileDiff(
                oldPath: try RelativePath("empty_file"),
                newPath: try RelativePath("empty_file"),
                diffType: .changed,
                oldFileMode: nil,
                newFileMode: "100644",
                addedLineNumbers: [],
                deletedLineNumbers: []
            ),
        ])
    }

    func test_renamedFile() throws {
        try check(diffName: "renamedFile", expectedResult: [
            GitDiffParser.FileDiff(
                oldPath: try RelativePath("project.yml"),
                newPath: try RelativePath("pr.yml"),
                diffType: .changed,
                oldFileMode: nil,
                newFileMode: nil,
                addedLineNumbers: [],
                deletedLineNumbers: []
            ),
        ])
    }

    func test_noNewLineAtEndOfFile() throws {
        try check(diffName: "noNewLine", expectedResult: [
            GitDiffParser.FileDiff(
                oldPath: try RelativePath("file.yml"),
                newPath: try RelativePath("file.yml"),
                diffType: .changed,
                oldFileMode: nil,
                newFileMode: nil,
                addedLineNumbers: [5],
                deletedLineNumbers: [5]
            ),
        ])
    }

    func test_binaryFilesDiffer() throws {
        try check(diffName: "binary", expectedResult: [
            GitDiffParser.FileDiff(
                oldPath: nil,
                newPath: try RelativePath("binary_files_differ_path"),
                diffType: .created,
                oldFileMode: nil,
                newFileMode: "100644",
                addedLineNumbers: [],
                deletedLineNumbers: []
            ),
        ])
    }

    func test_spacesAndBackslashDiffLine() throws {
        try check(diffName: "spacesAndBackslashDiffLine", expectedResult: [
            GitDiffParser.FileDiff(
                oldPath: try RelativePath("public/social/listen/world/than/friend.swift"),
                newPath: try RelativePath("public/social/listen/world/than/friend.swift"),
                diffType: .changed,
                oldFileMode: nil,
                newFileMode: nil,
                addedLineNumbers: [286],
                deletedLineNumbers: (278 ... 283).asArray + [305]
            ),
        ])
    }

    /// This is a correctly generated diff for a deleted pdf file. But the diff itself is broken.
    func test_pdf_lineByLineDiff_corruptedDiffFormat() throws {
        // given
        let logger = LoggingMock()
        logger.given(.logLevel(getter: .verbose))
        let parser = GitDiffParser(logger: logger)
        let diff = try Bundle.module.readStubText(path: "diffs/pdf_deleted.diff")

        // when
        let results = try parser.parseGitDiff(diff, ignoreFormatErrors: true)

        // then
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(
            results[0].oldPath,
            try RelativePath("friend/interesting/among/guy/in/affect.pdf")
        )
        XCTAssertEqual(results[0].newPath, nil)
        XCTAssertEqual(results[0].deletedLineNumbers.count, 312)

        XCTAssertEqual(
            results[1],
            GitDiffParser.FileDiff(
                oldPath: try RelativePath("project.yml"),
                newPath: try RelativePath("pr.yml"),
                diffType: .changed,
                oldFileMode: nil,
                newFileMode: nil,
                addedLineNumbers: [],
                deletedLineNumbers: []
            )
        )
    }
}
