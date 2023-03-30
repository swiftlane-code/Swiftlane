//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol SwiftCodeParsing {
    func imports(in code: String) -> [String]
    func typeDeclarations(in code: String) -> [String]
    func extendedTypes(in code: String) -> [String]
}

public class SwiftCodeParser {
    private let logger: Logging
    private let filesManager: FSManaging

    private let declarationRegex: NSRegularExpression
    private let extensionRegex: NSRegularExpression
    private let importRegex: NSRegularExpression

    public init(
        logger: Logging,
        filesManager: FSManaging
    ) throws {
        self.logger = logger
        self.filesManager = filesManager

        declarationRegex = try NSRegularExpression(
            pattern: #"(?:class|struct|enum) (\w+)"#,
            options: .anchorsMatchLines
        )
        extensionRegex = try NSRegularExpression(pattern: #"public extension (\w+)"#, options: .anchorsMatchLines)
        importRegex = try NSRegularExpression(
            pattern: #"^\s*(?:@testable\s+)?import\s+(\w+)"#,
            options: .anchorsMatchLines
        )
    }
}

extension SwiftCodeParser: SwiftCodeParsing {
    public func imports(in code: String) -> [String] {
        importRegex.matchesGroups(in: code)
            .map { String($0[1]) }
            .removingDuplicates
    }

    public func typeDeclarations(in code: String) -> [String] {
        declarationRegex.matchesGroups(in: code)
            .map { String($0[1]) }
            .removingDuplicates
    }

    public func extendedTypes(in code: String) -> [String] {
        extensionRegex.matchesGroups(in: code)
            .map { String($0[1]) }
            .removingDuplicates
    }
}
