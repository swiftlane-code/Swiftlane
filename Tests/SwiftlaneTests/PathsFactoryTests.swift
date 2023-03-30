//

import Foundation
import SwiftlaneCore
import SwiftlaneCoreMocks
import SwiftlaneUnitTestTools
import XCTest

@testable import Swiftlane

class PathsFactoryTests: XCTestCase {
    var filesManager: FSManagingMock!
    var logger: LoggingMock!

    override func setUp() {
        super.setUp()

        logger = LoggingMock()

        filesManager = FSManagingMock()
    }

    override func tearDown() {
        logger = nil

        filesManager = nil

        super.tearDown()
    }

    func test_pathsAreRelativeToCorrectOrigin() throws {
        // given
        let pathsConfig = try makePathsConfig()
        let factory = PathsFactory(
            pathsConfig: pathsConfig,
            projectDir: try AbsolutePath("/project/dir"),
            filesManager: filesManager,
            logger: logger
        )

        // when & then
        XCTAssertEqual(
            factory.xclogparserJSONReport.string,
            "/project/dir/resultsDir/xclogparserJSONReportName"
        )

        XCTAssertEqual(
            factory.xclogparserHTMLReportDir.string,
            "/project/dir/resultsDir/xclogparserHTMLReportDirName"
        )

        XCTAssertEqual(
            factory.mergedJUnit.string,
            "/project/dir/resultsDir/mergedJUnitName"
        )

        XCTAssertEqual(
            factory.mergedXCResult.string,
            "/project/dir/resultsDir/mergedXCResultName"
        )

        XCTAssertEqual(
            factory.xccovFile.string,
            "/project/dir/resultsDir/xccovFileName"
        )

        XCTAssertEqual(
            factory.projectFile.string,
            "/project/dir/projectFile"
        )

        XCTAssertEqual(
            factory.derivedDataDir.string,
            "/project/dir/derivedDataDir"
        )

        XCTAssertEqual(
            factory.testRunsDerivedDataDir.string,
            "/project/dir/testRunsDerivedDataDir"
        )

        XCTAssertEqual(
            factory.logsDir.string,
            "/project/dir/logsDir"
        )

        XCTAssertEqual(
            factory.resultsDir.string,
            "/project/dir/resultsDir"
        )

        XCTAssertEqual(
            factory.swiftlintConfig.string,
            "/project/dir/swiftlintConfigPath"
        )

        XCTAssertEqual(
            factory.archivesDir.string,
            "/project/dir/archives"
        )

        XCTAssertEqual(
            factory.warningsJsonsDir.string,
            "/project/dir/swiftlintWarningsJsonsFolder"
        )

        XCTAssertEqual(
            factory.tempDir.string,
            "/project/dir/tempDir"
        )
    }

    func makePathsConfig() throws -> PathsConfig {
        PathsConfig(
            xclogparserJSONReportName: try RelativePath("xclogparserJSONReportName"),
            xclogparserHTMLReportDirName: try RelativePath("xclogparserHTMLReportDirName"),
            mergedJUnitName: try RelativePath("mergedJUnitName"),
            mergedXCResultName: try RelativePath("mergedXCResultName"),
            xccovFileName: try RelativePath("xccovFileName"),
            projectFile: try RelativePath("projectFile"),
            derivedDataDir: try Path("derivedDataDir"),
            testRunsDerivedDataDir: try Path("testRunsDerivedDataDir"),
            logsDir: try Path("logsDir"),
            resultsDir: try Path("resultsDir"),
            archivesDir: try Path("archives"),
            swiftlintConfigPath: try Path("swiftlintConfigPath"),
            swiftlintWarningsJsonsFolder: try Path("swiftlintWarningsJsonsFolder"),
            tempDir: try Path("tempDir"),
            xcodebuildFormatterPath: try Path("xcodebuildFormatterPath")
        )
    }
}
