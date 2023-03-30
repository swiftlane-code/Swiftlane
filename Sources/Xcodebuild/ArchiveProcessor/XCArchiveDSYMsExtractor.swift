//

import Foundation
import SwiftlaneCore

public protocol XCArchiveDSYMsExtracting {
    /// Deobfuscate symbols' names in dSYMs inside `.xcarchive` and zip all dsyms into a `.zip` archive.
    func extractDsyms(
        xcarchivePath: AbsolutePath,
        dsymsZipPath: AbsolutePath
    ) throws
}

public final class XCArchiveDSYMsExtractor {
    private let logger: Logging
    private let shell: ShellExecuting
    private let filesManager: FSManaging
    private let timeMeasurer: TimeMeasurer

    public init(
        logger: Logging,
        shell: ShellExecuting,
        filesManager: FSManaging,
        timeMeasurer: TimeMeasurer
    ) {
        self.logger = logger
        self.shell = shell
        self.filesManager = filesManager
        self.timeMeasurer = timeMeasurer
    }
}

extension XCArchiveDSYMsExtractor: XCArchiveDSYMsExtracting {
    /// Explanation: https://blog.embrace.io/deobfuscating-ios-bitcode-symbols/
    /// https://stackoverflow.com/questions/34363485/why-does-recompiling-from-bitcode-make-me-unable-to-symbolicate-in-xcode-ad-hoc
    /// https://developer.apple.com/documentation/xcode/adding-identifiable-symbol-names-to-a-crash-report
    public func extractDsyms(
        xcarchivePath: AbsolutePath,
        dsymsZipPath: AbsolutePath
    ) throws {
        try timeMeasurer.measure(description: "Extracting dSYMs") {
            let uuidRegex = try NSRegularExpression(
                pattern: #"UUID: ([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})"#,
                options: .anchorsMatchLines
            )

            let dsymsDir = try xcarchivePath.appending(path: "dSYMs")

            let dsymsFiles = try filesManager.ls(dsymsDir)
                .filter { $0.hasSuffix(".dSYM") }

            try dsymsFiles
                .forEach { dsymFile in
                    logger.debug("Processing \(dsymFile)...")

                    let dwarfdumpOutput = try shell.run(
                        "dwarfdump -u " + dsymFile.string.quoted,
                        log: .commandAndOutput(outputLogLevel: .verbose)
                    ).stdoutText.unwrap(
                        errorDescription: "Unexpected nil output of dwarfdump."
                    )

                    let dsymsUUIDs = uuidRegex.matchesGroups(in: dwarfdumpOutput).map { $0[1] }

                    let symbolMaps = try dsymsUUIDs
                        .map {
                            try xcarchivePath.appending(
                                path: "BCSymbolMaps".appendingPathComponent($0 + ".bcsymbolmap")
                            )
                        }
                        .filter {
                            filesManager.fileExists($0)
                        }

                    try symbolMaps.forEach { symbolMapFile in
                        try shell.run(
                            "dsymutil --symbol-map '\(symbolMapFile)' '\(dsymFile)'",
                            log: .commandAndOutput(outputLogLevel: .verbose)
                        )
                    }
                }

            try timeMeasurer.measure(description: "Compressing \(dsymsFiles.count) dsyms") {
                try shell.run(
                    "cd '\(dsymsDir)' && zip -r '\(dsymsZipPath)' *.dSYM",
                    log: .commandAndOutput(outputLogLevel: .info)
                )
            }
        }
    }
}
