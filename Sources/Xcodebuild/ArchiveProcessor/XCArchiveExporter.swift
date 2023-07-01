//

import Foundation
import SwiftlaneCore

public protocol XCArchiveExporting {
    /// Export `.ipa` from `.xcarchive`.
    /// - Parameters:
    ///   - archivePath: path to `.xcarhive`.
    ///   - config: export config.
    ///   - exportedIpaPath: path to exported `.ipa`.
    func exportArchive(
        archivePath: AbsolutePath,
        config: XCArchiveExportOptions,
        exportedIpaPath: AbsolutePath
    ) throws
}

public final class XCArchiveExporter {
    private let logger: Logging
    private let shell: ShellExecuting
    private let filesManager: FSManaging
    private let timeMeasurer: TimeMeasuring
    private let xcodebuildCommand: XcodebuildCommandProducing

    public init(
        logger: Logging,
        shell: ShellExecuting,
        filesManager: FSManaging,
        timeMeasurer: TimeMeasuring,
        xcodebuildCommand: XcodebuildCommandProducing
    ) {
        self.logger = logger
        self.shell = shell
        self.filesManager = filesManager
        self.timeMeasurer = timeMeasurer
        self.xcodebuildCommand = xcodebuildCommand
    }
}

extension XCArchiveExporter: XCArchiveExporting {
    /// Returns path to generated ipa.
    public func exportArchive(
        archivePath: AbsolutePath,
        config: XCArchiveExportOptions,
        exportedIpaPath: AbsolutePath
    ) throws {
        let generatedPlistPath = try archivePath.deletingLastComponent.appending(path: "exportOptions.plist")

        let plistEncoder = PropertyListEncoder()
        plistEncoder.outputFormat = .xml
        let encodedPlist = try plistEncoder.encode(config)
        try filesManager.write(generatedPlistPath, data: encodedPlist)

        let plistText = try filesManager.readText(generatedPlistPath, log: true)

        logger.important("Generated export params plist: \n" + plistText)

        try timeMeasurer.measure(description: "Exporting archive") {
            try shell.run([
                xcodebuildCommand.produce(),
                "-exportArchive",
                "-exportOptionsPlist " + generatedPlistPath.string.quoted,
                "-archivePath " + archivePath.string.quoted,
                "-exportPath " + exportedIpaPath.deletingLastComponent.string.quoted,
            ], log: .commandAndOutput(outputLogLevel: .verbose))
        }

        let generatedIpa = try filesManager.find(exportedIpaPath.deletingLastComponent)
            .first { $0.hasSuffix(".ipa") }
            .unwrap(errorDescription: "Unable to find exported .ipa file.")

        try filesManager.move(generatedIpa, newPath: exportedIpaPath)

        logger.success("Exported .ipa \(exportedIpaPath.string.quoted).")
    }
}
