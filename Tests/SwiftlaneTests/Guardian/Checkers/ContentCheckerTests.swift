
import SwiftlaneCore
import SwiftlaneCoreMocks
import XCTest

@testable import Swiftlane

class ContentCheckerTests: XCTestCase {
    var checker: ContentChecking!
    var logger: LoggingMock!
    var filesManager: FSManagingMock!
    var git: GitProtocolMock!
    var reporter: ContentCheckerReportingMock!

    override func setUp() {
        super.setUp()

        logger = .init()
        filesManager = .init()
        git = .init()
        reporter = .init()

        checker = ContentChecker(
            logger: logger,
            filesManager: filesManager,
            git: git,
            reporter: reporter
        )
    }

    override func tearDown() {
        super.tearDown()

        filesManager = nil
        git = nil
        checker = nil
        reporter = nil
    }

    func test_tabsAreDetected() throws {
        // given
        let projectDir = AbsolutePath.random(lastComponent: "projectDir")
        let filesList = [
            "file1.swift",
            "file2.swift",
            "file3.swift",
            "file4.swift",
            "notASwiftFile.md",
            "notASwiftFile.txt",
            "notASwiftFile.yml",
        ].map { AbsolutePath.random(lastComponent: $0) }

        let codeWithTabs = try Bundle.module.readStubText(path: "TabsIndentedFile.txt")
        let codeWithSpaces = try Bundle.module.readStubText(path: "SpacesIndentedFile.txt")

        git.given(
            .filesChangedInLastCommit(
                repo: .value(projectDir),
                onlyExistingFiles: .value(true),
                willReturn: filesList
            )
        )

        filesManager.given(.readText(.value(filesList[0]), log: .any, willReturn: codeWithTabs))
        filesManager.given(.readText(.value(filesList[1]), log: .any, willReturn: codeWithSpaces))
        filesManager.given(.readText(.value(filesList[2]), log: .any, willReturn: codeWithSpaces))
        filesManager.given(.readText(.value(filesList[3]), log: .any, willReturn: codeWithTabs))

        // when
        try checker.checkTabsInChangedFiles(
            projectDir: projectDir,
            contents: [
                ContentChecker.Content(
                    fileName: .hasSuffix(".swift"),
                    regexChanges: .regex(NSRegularExpression(pattern: "^\\s*(\t)", options: .anchorsMatchLines)),
                    errorMessage: ""
                ),
            ]
        )

        // then
        reporter.verify(
            .reportFailsDetected(
                .value(
                    [
                        ContentChecker.FileBadLinesInfo(file: filesList[0], lines: [7, 8, 9, 12], errorObject: ""),
                        ContentChecker.FileBadLinesInfo(file: filesList[3], lines: [7, 8, 9, 12], errorObject: ""),
                    ]
                )
            )
        )
    }
}
