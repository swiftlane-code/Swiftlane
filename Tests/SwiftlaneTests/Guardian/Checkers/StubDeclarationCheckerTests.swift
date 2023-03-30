//

import Foundation
import SwiftlaneCore
import SwiftlaneCoreMocks
import SwiftlaneUnitTestTools
import XCTest

@testable import Swiftlane

class StubDeclarationCheckerTests: XCTestCase {
    var checker: StubDeclarationChecker!

    var logger: LoggingMock!
    var filesManager: FSManagingMock!
    var reporter: StubDeclarationReportingMock!
    var slatherService: SlatherServicingMock!
    var codeParser: SwiftCodeParsingMock!
    var projectDir = AbsolutePath.random(lastComponent: "projectDir")

    override func setUpWithError() throws {
        try super.setUpWithError()

        logger = LoggingMock()
        filesManager = FSManagingMock()
        reporter = StubDeclarationReportingMock()
        slatherService = SlatherServicingMock()
        codeParser = SwiftCodeParsingMock()

        checker = StubDeclarationChecker(
            logger: logger,
            filesManager: filesManager,
            slatherService: slatherService,
            reporter: reporter,
            codeParser: codeParser,
            config: StubDeclarationConfig(
                enabled: true,
                fail: true,
                projectDir: projectDir,
                mocksTargetsPath: try NSRegularExpression(pattern: "^mocks/(\\w+)", options: .anchorsMatchLines),
                testsTargetsPath: try NSRegularExpression(pattern: "^tests/(\\w+)", options: .anchorsMatchLines),
                ignoredFiles: [.equals("mocks/Target1/test_file_1.swift")]
            )
        )

        logger.given(.logLevel(getter: .verbose))
    }

    override func tearDown() {
        super.tearDown()

        checker = nil

        logger = nil
        filesManager = nil
        reporter = nil
        slatherService = nil
        codeParser = nil
    }

    func test_violationsAreDetectedCorrectly() throws {
        // given
        let mainFiles: [AbsolutePath] = [
            try! projectDir.appending(path: "Target1/file_1.swift"),
            try! projectDir.appending(path: "Target1/file_2.swift"),
            try! projectDir.appending(path: "Target1/file_3.swift"),
            try! projectDir.appending(path: "Target2/file_4.swift"),
            try! projectDir.appending(path: "Target2/file_5.swift"),
            try! projectDir.appending(path: "Target2/file_6.swift"),
        ]

        let testsFiles: [AbsolutePath] = [
            try! projectDir.appending(path: "tests/Target1/test_file_1.swift"),
            try! projectDir.appending(path: "tests/Target2/test_file_2.swift"),
            try! projectDir.appending(path: "mocks/Target1/test_file_1.swift"),
            try! projectDir.appending(path: "mocks/Target2/test_file_2.swift"),
        ]

        let allFiles = mainFiles + testsFiles

        filesManager.given(.find(.value(projectDir), file: .any, line: .any, willReturn: allFiles))

        slatherService.given(
            .readTestableTargetsNames(
                projectDir: .value(projectDir),
                fileName: ".testable.targets.generated.txt",
                willReturn: [
                    "Target1",
                    "Target2",
                ]
            )
        )

        // main files

        for file in mainFiles {
            filesManager.given(.readText(.value(file), log: .any, willReturn: file.string))
        }

        codeParser.given(.typeDeclarations(in: .any, willReturn: []))
        codeParser.given(.typeDeclarations(in: .value(mainFiles[0].string), willReturn: ["A", "B", "C"]))
        codeParser.given(.typeDeclarations(in: .value(mainFiles[3].string), willReturn: ["D", "E", "C"]))

        // tests and mocks files
        for testFile in testsFiles {
            filesManager.given(.readText(.value(testFile), log: .any, willReturn: testFile.string))
        }

        codeParser.given(.extendedTypes(in: .any, willReturn: []))
        codeParser.given(.imports(in: .any, willReturn: []))

        codeParser.given(.extendedTypes(in: .value(testsFiles[0].string), willReturn: ["A", "D"]))
        codeParser.given(.imports(in: .value(testsFiles[0].string), willReturn: ["Target1", "Target2"]))

        codeParser.given(.extendedTypes(in: .value(testsFiles[3].string), willReturn: ["A", "D"]))
        codeParser.given(.imports(in: .value(testsFiles[3].string), willReturn: ["Target1", "Target2"]))

        // when
        try checker.checkMocksDeclarations()

        // then
        filesManager.verify(.readText(.value(testsFiles[2]), log: .any), count: .never)

        reporter.verify(
            .reportViolation(
                file: .value(try! testsFiles[0].relative(to: projectDir).string),
                violations: .matching { violations in
                    violations == [
                        StubDeclarationViolation(
                            typeName: "D",
                            typeDefinedIn: "Target2",
                            extensionMayBeIn: ["Target2", "Target2Mocks", "Target2Tests"],
                            extensionDefinedIn: "Target1"
                        ),
                    ]
                }
            )
        )

        reporter.verify(
            .reportViolation(
                file: .value(try! testsFiles[3].relative(to: projectDir).string),
                violations: .matching { violations in
                    violations == [
                        StubDeclarationViolation(
                            typeName: "A",
                            typeDefinedIn: "Target1",
                            extensionMayBeIn: ["Target1", "Target1Mocks", "Target1Tests"],
                            extensionDefinedIn: "Target2"
                        ),
                    ]
                }
            )
        )

        reporter.verify(.reportViolation(file: .any, violations: .any), count: .exactly(2))

        reporter.verify(.reportSuccessIfNeeded(), count: .once)
    }
}
