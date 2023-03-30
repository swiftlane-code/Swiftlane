
import Foundation
import Git
import SwiftlaneCore

// sourcery: AutoMockable
public protocol ContentChecking {
    func checkTabsInChangedFiles(projectDir: AbsolutePath, contents: [ContentChecker.Content]) throws
}

public extension ContentChecker {
    struct Content: Decodable {
        public let fileName: StringMatcher
        public let regexChanges: StringMatcher
        public let errorMessage: String
    }
}

public extension ContentChecker {
    struct FileBadLinesInfo: Equatable {
        public let file: AbsolutePath
        public let lines: [Int]
        public let errorObject: String
    }
}

public final class ContentChecker {
    private let logger: Logging
    private let filesManager: FSManaging
    private let git: GitProtocol
    private let reporter: ContentCheckerReporting

    public init(
        logger: Logging,
        filesManager: FSManaging,
        git: GitProtocol,
        reporter: ContentCheckerReporting
    ) {
        self.logger = logger
        self.filesManager = filesManager
        self.git = git
        self.reporter = reporter
    }

    private func getChangedFiles(projectDir: AbsolutePath) throws -> [AbsolutePath] {
        try git.filesChangedInLastCommit(
            repo: projectDir,
            onlyExistingFiles: true
        )
    }
}

extension ContentChecker: ContentChecking {
    public func checkTabsInChangedFiles(projectDir: AbsolutePath, contents: [ContentChecker.Content]) throws {
        let mrChangedFiles = try getChangedFiles(projectDir: projectDir)

        var fails: [FileBadLinesInfo] = []

        for rule in contents {
            try mrChangedFiles
                .filter { rule.fileName.isMatching($0.string) }
                .forEach { file in
                    let badLinesNumbers = try filesManager.readText(file, log: true)
                        .split(
                            separator: "\n",
                            omittingEmptySubsequences: false
                        )
                        .enumerated()
                        .compactMap { lineNumber, line -> Int? in
                            guard rule.regexChanges.isMatching(String(line)) else {
                                return nil
                            }
                            return lineNumber + 1
                        }

                    if !badLinesNumbers.isEmpty {
                        fails.append(
                            FileBadLinesInfo(
                                file: file,
                                lines: badLinesNumbers,
                                errorObject: rule.errorMessage
                            )
                        )
                    }
                }
        }

        if fails.isEmpty {
            return reporter.reportSuccess()
        }

        return reporter.reportFailsDetected(fails)
    }
}
