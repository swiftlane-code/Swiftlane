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
        filePath: AbsolutePath
    ) throws -> [SlatherFileCodeCoverage]

    func readTestableTargetsNames(
        filePath: AbsolutePath
    ) throws -> [String]
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
        filePath: AbsolutePath
    ) throws -> [SlatherFileCodeCoverage] {
        let data = try filesManager.readData(filePath, log: true)
        let decoder = JSONDecoder()
        let result = try decoder.decode([SlatherFileCodeCoverage].self, from: data)
        return result
    }

    public func readTestableTargetsNames(
        filePath: AbsolutePath
    ) throws -> [String] {
        let content = try filesManager.readText(filePath, log: true)
        return content.components(separatedBy: "\n")
    }
}
