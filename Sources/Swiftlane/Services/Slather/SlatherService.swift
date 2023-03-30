//

import Foundation
import SwiftlaneCore
import Yams

/// Slather coverage JSON model
public struct SlatherFileCodeCoverage: Decodable {
    /// Relative path to file
    public let file: String
    /// Count of executions of lines in file
    /// nil - non-executable line
    /// 0 - executable line which is not covered with unit tests
    /// >= 1 - executable line which is covered with unit tests
    public let coverage: [Int?]
}

// sourcery: AutoMockable
public protocol SlatherServicing {
    func parseCoverageJSON(
        projectDir: AbsolutePath,
        reportFileName: String?,
        outputDirPath: Path?
    ) throws -> [SlatherFileCodeCoverage]

    func readTestableTargetsNames(projectDir: AbsolutePath, fileName: String?) throws -> [String]
}

public extension SlatherServicing {
    func parseCoverageJSON(
        projectDir: AbsolutePath
    ) throws -> [SlatherFileCodeCoverage] {
        try parseCoverageJSON(
            projectDir: projectDir,
            reportFileName: nil,
            outputDirPath: nil
        )
    }

    func readTestableTargetsNames(projectDir: AbsolutePath) throws -> [String] {
        try readTestableTargetsNames(projectDir: projectDir, fileName: nil)
    }
}

public class SlatherService {
    private let filesManager: FSManaging

    public init(
        filesManager: FSManaging
    ) {
        self.filesManager = filesManager
    }
}

extension SlatherService: SlatherServicing {
    public func parseCoverageJSON(
        projectDir: AbsolutePath,
        reportFileName: String?,
        outputDirPath: Path?
    ) throws -> [SlatherFileCodeCoverage] {
        let reportFileName = reportFileName ?? "coverage.json"
        let outputDirPath = try outputDirPath ?? Path("builds/results")

        let reportPath = outputDirPath
            .makeAbsoluteIfIsnt(relativeTo: projectDir)
            .appending(path: try! RelativePath(reportFileName))

        let data = try filesManager.readData(reportPath, log: true)
        let decoder = JSONDecoder()
        let result = try decoder.decode([SlatherFileCodeCoverage].self, from: data)
        return result
    }

    public func readTestableTargetsNames(projectDir: AbsolutePath, fileName: String?) throws -> [String] {
        let fileName = fileName ?? ".testable.targets.generated.txt"

        let configFileName = try! RelativePath(fileName)
        let configPath = projectDir.appending(path: configFileName)

        let content = try filesManager.readText(configPath, log: true)

        return content.components(separatedBy: "\n")
    }
}
