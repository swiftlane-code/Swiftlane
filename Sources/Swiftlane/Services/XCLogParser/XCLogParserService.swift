//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol XCLogParserServicing {
    func readXCLogParserReport(reportPath: AbsolutePath) throws -> XCLogParserIssuesReport
    func generateReportHTML(derivedDataPath: AbsolutePath, outputDirPath: AbsolutePath) throws
    func generateReportIssues(derivedDataPath: AbsolutePath, outputFilePath: AbsolutePath) throws
}

public class XCLogParserService {
    private let filesManager: FSManaging
    private let shell: ShellExecuting

    public init(
        filesManager: FSManaging,
        shell: ShellExecuting
    ) {
        self.filesManager = filesManager
        self.shell = shell
    }
}

extension XCLogParserService: XCLogParserServicing {
    public func readXCLogParserReport(reportPath: AbsolutePath) throws -> XCLogParserIssuesReport {
        let data = try filesManager.readData(reportPath, log: true)

        return try JSONDecoder().decode(
            XCLogParserIssuesReport.self,
            from: data
        )
    }

    public func generateReportHTML(derivedDataPath: AbsolutePath, outputDirPath: AbsolutePath) throws {
        if filesManager.fileExists(outputDirPath) {
            try filesManager.delete(outputDirPath)
        }

        try shell.run(
            "xclogparser parse --derived_data \(derivedDataPath) --reporter html --project \"*\" --rootOutput \(outputDirPath)",
            log: .commandAndOutput(outputLogLevel: .debug)
        )
    }

    public func generateReportIssues(derivedDataPath: AbsolutePath, outputFilePath: AbsolutePath) throws {
        if filesManager.fileExists(outputFilePath) {
            try filesManager.delete(outputFilePath)
        }

        try shell.run(
            "xclogparser parse --derived_data \(derivedDataPath) --reporter issues --project \"*\" --output \(outputFilePath)",
            log: .commandAndOutput(outputLogLevel: .debug)
        )
    }
}
