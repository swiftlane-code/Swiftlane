//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol XCCOVServicing {
    func generateAndParseCoverageReport(
        xcresultPath: AbsolutePath,
        generatedCoverageFilePath: AbsolutePath
    ) throws -> XCCOVCoverageReport
}

public class XCCOVService {
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

extension XCCOVService: XCCOVServicing {
    public func generateAndParseCoverageReport(
        xcresultPath: AbsolutePath,
        generatedCoverageFilePath: AbsolutePath
    ) throws -> XCCOVCoverageReport {
        try shell.run(
            "xcrun xccov view --report --json \"\(xcresultPath)\" > \"\(generatedCoverageFilePath)\"",
            log: .commandOnly
        )

        let data = try filesManager.readData(generatedCoverageFilePath, log: true)
        let decoder = JSONDecoder()
        let result = try decoder.decode(XCCOVCoverageReport.self, from: data)
        return result
    }
}
