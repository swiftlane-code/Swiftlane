//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol WarningsStoraging {
    var warningsJsonsFolder: AbsolutePath { get }

    func readListOfDirectories() throws -> [String]
    func read(jsonName: String) throws -> [SwiftLintViolation]
    func save(jsonName: String, warnings: [SwiftLintViolation]) throws
}

public class WarningsStorage {
    private let filesManager: FSManaging
    private let config: Config

    public init(
        filesManager: FSManaging,
        config: Config
    ) {
        self.filesManager = filesManager
        self.config = config
    }

    private func path(to jsonName: String) -> AbsolutePath {
        warningsJsonsFolder
            .appending(path: try! RelativePath(jsonName + ".json"))
    }
}

extension WarningsStorage: WarningsStoraging {
    public var warningsJsonsFolder: AbsolutePath {
        config.warningsJsonsFolder
    }

    public func readListOfDirectories() throws -> [String] {
        try filesManager.find(warningsJsonsFolder)
            .filter { $0.hasSuffix(".json") }
            .map(\.lastComponent.deletingExtension.string)
    }

    public func read(jsonName: String) throws -> [SwiftLintViolation] {
        let file = path(to: jsonName)
        let data = try filesManager.readData(file, log: true)
        let decoder = JSONDecoder()
        return try decoder.decode([SwiftLintViolation].self, from: data)
    }

    public func save(jsonName: String, warnings: [SwiftLintViolation]) throws {
        let encoder = JSONEncoder()
        //        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(
            warnings.sorted(by: { lhs, rhs in
                func comparable(_ warning: SwiftLintViolation) -> [String] {
                    [warning.file, String(warning.line), warning.messageText]
                }
                return comparable(lhs).lexicographicallyPrecedes(comparable(rhs))
            })
        )
        let text = try String(data: data, encoding: .utf8).unwrap(
            errorDescription: "Unable to init string from data"
        )
        let file = path(to: jsonName)
        try filesManager.write(file, text: text)
    }
}
