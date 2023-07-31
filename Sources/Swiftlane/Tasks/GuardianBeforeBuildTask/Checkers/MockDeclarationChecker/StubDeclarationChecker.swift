//

import Foundation
import Guardian
import SwiftlaneCore

public protocol StubDeclarationChecking {
    func checkMocksDeclarations() throws
}

public struct StubDeclarationConfig {
    public let enabled: Bool
    public let fail: Bool // fail or warn
    public let projectDir: AbsolutePath
    public let mocksTargetsPath: NSRegularExpression
    public let testsTargetsPath: NSRegularExpression
    public let ignoredFiles: [StringMatcher]
    public let testableTargetsListFilePath: Path
}

public struct StubDeclarationViolation: Equatable {
    public let typeName: String
    public let typeDefinedIn: String
    public let extensionMayBeIn: [String]
    public let extensionDefinedIn: String
}

public final class StubDeclarationChecker {
    private let logger: Logging
    private let filesManager: FSManaging
    private let reporter: StubDeclarationReporting
    private let slatherService: SlatherServicing
    private let codeParser: SwiftCodeParsing

    private let config: StubDeclarationConfig

    public init(
        logger: Logging,
        filesManager: FSManaging,
        slatherService: SlatherServicing,
        reporter: StubDeclarationReporting,
        codeParser: SwiftCodeParsing,
        config: StubDeclarationConfig
    ) {
        self.logger = logger
        self.filesManager = filesManager
        self.slatherService = slatherService
        self.reporter = reporter
        self.codeParser = codeParser
        self.config = config
    }

    /// Scan types declarations in main targets.
    /// - Returns: Dictionary where key is name of a type and value is set of targets names a type with such name is defined in.
    private func scanDefinitions(allFiles: [(AbsolutePath, RelativePath)]) throws -> [String: Set<String>] {
        let testableTargetsNames = try slatherService.readTestableTargetsNames(
            filePath: config.testableTargetsListFilePath.makeAbsoluteIfIsnt(relativeTo: config.projectDir)
        )

        func targetName(filePath: RelativePath) -> String {
            filePath.firstComponent
        }

        // Filter only files from targets listed in slather.yml.
        let scannedFiles = allFiles
            .filter { _, relativePath in
                testableTargetsNames.contains(targetName(filePath: relativePath))
            }

        var result = [String: Set<String>]()

        logger.info("\(scannedFiles.count) files will be scanned for type definitions.")

        try scannedFiles.forEach { filePath, relativePath in
            let code = try filesManager.readText(filePath, log: false)

            let fileDefinitions = codeParser.typeDeclarations(in: code)

            if !fileDefinitions.isEmpty {
                logger.debug("Found \(fileDefinitions.count) definitions in \(relativePath)")
            }

            fileDefinitions.forEach {
                result[$0, default: []].insert(targetName(filePath: relativePath))
            }
        }

        return result
    }

    private func findAllSwiftFiles() throws -> [(AbsolutePath, RelativePath)] {
        try filesManager.find(config.projectDir)
            .filter { $0.hasSuffix(".swift") }
            .compactMap { [self] filePath in
                (try? filePath.relative(to: config.projectDir)).map {
                    (filePath, $0)
                }
            }
            .filter { _, relativePath in
                !config.ignoredFiles.isMatching(string: relativePath.string)
            }
    }

    private func filterFilesAndExtractTargetName(
        allFiles: [(AbsolutePath, RelativePath)],
        pathRegex: NSRegularExpression
    ) -> [(AbsolutePath, RelativePath, targetName: String)] {
        allFiles.compactMap { absolutePath, relativePath in
            pathRegex.matchesGroups(in: relativePath.string)
                .map { String($0[1]) }
                .first
                .map { (absolutePath: absolutePath, relativePath: relativePath, targetName: $0) }
        }
    }
}

extension StubDeclarationChecker: StubDeclarationChecking {
    public func checkMocksDeclarations() throws {
        guard config.enabled else {
            reporter.reportExpiredToDoCheckerDisabled()
            return
        }

        let swiftFiles = try findAllSwiftFiles()
        let mocksFiles = filterFilesAndExtractTargetName(allFiles: swiftFiles, pathRegex: config.mocksTargetsPath)
        let testsFiles = filterFilesAndExtractTargetName(allFiles: swiftFiles, pathRegex: config.testsTargetsPath)

        logger.info("Swift files: \(swiftFiles.count)")
        logger.info("mocks files: \(mocksFiles.count)")
        logger.info("tests files: \(testsFiles.count)")

        let definitions = try scanDefinitions(allFiles: swiftFiles)

        logger.info("\((mocksFiles + testsFiles).count) files will be scanned to look for extensions in wrong places.")

        try (mocksFiles + testsFiles).forEach { [self] filePath, relativePath, targetName in
            let code = try filesManager.readText(filePath, log: false)

            let extendedTypesNames = codeParser.extendedTypes(in: code)
            let imports = codeParser.imports(in: code)

            if !extendedTypesNames.isEmpty {
                logger.debug("Found \(extendedTypesNames.count) extensions in \(relativePath)")
            }

            let violations: [StubDeclarationViolation] = extendedTypesNames
                .compactMap { typeName in
                    guard let typeDefinedIn = definitions[typeName] else {
                        return nil
                    }

                    let probablyDefinedIn = typeDefinedIn.filter { imports.contains($0) }

                    if probablyDefinedIn.count > 1 {
                        logger
                            .error("Unexpected ambigious definition place of \(typeName) is one of \(probablyDefinedIn)")
                    }

                    guard let definedIn = probablyDefinedIn.first else {
                        return nil
                    }

                    let extensionMayBeIn = [definedIn, definedIn + "Mocks", definedIn + "Tests"]

                    guard !extensionMayBeIn.contains(targetName) else {
                        return nil
                    }

                    return StubDeclarationViolation(
                        typeName: typeName,
                        typeDefinedIn: definedIn,
                        extensionMayBeIn: extensionMayBeIn,
                        extensionDefinedIn: targetName
                    )
                }

            if !violations.isEmpty {
                reporter.reportViolation(
                    file: try filePath.relative(to: config.projectDir).string,
                    violations: violations
                )
            }
        }

        reporter.reportSuccessIfNeeded()
    }
}
