//

import Foundation

import AppStoreConnectAPI
import AppStoreConnectJWT
import Provisioning
import Simulator
import SwiftlaneCore
import Xcodebuild

public struct ArchiveAndExportIPATaskConfig {
    public let projectFile: AbsolutePath
    public let derivedDataDir: AbsolutePath
    public let logsDir: AbsolutePath
    public let archivesDir: AbsolutePath
    public let scheme: String
    public let buildConfiguration: String
    public let ipaName: String
    public let provisionProfiles: [String: String]
    public let exportMethod: XCArchiveExportOptions.ExportMethod
    public let compileBitcode: Bool
    public let manageAppVersionAndBuildNumber: Bool?
    public let isUseRosetta: Bool
    public let xcodebuildFormatterCommand: String
}

/// Archive and export `.ipa`.
public final class ArchiveAndExportIPATask {
    private let simulatorProvider: SimulatorProviding
    private let logger: Logging
    private let shell: ShellExecuting
    private let archiveProcessor: XCArchiveExporting
    private let filesManager: FSManaging
    private let xcodeProjectPatcher: XcodeProjectPatching
    private let dsymsExtractor: XCArchiveDSYMsExtracting
    private let provisioningProfilesService: ProvisioningProfilesServicing

    private let config: ArchiveAndExportIPATaskConfig

    public init(
        simulatorProvider: SimulatorProviding,
        logger: Logging,
        shell: ShellExecuting,
        archiveProcessor: XCArchiveExporting,
        filesManager: FSManaging,
        xcodeProjectPatcher: XcodeProjectPatching,
        dsymsExtractor: XCArchiveDSYMsExtracting,
        provisioningProfilesService: ProvisioningProfilesServicing,
        config: ArchiveAndExportIPATaskConfig
    ) {
        self.simulatorProvider = simulatorProvider
        self.logger = logger
        self.shell = shell
        self.archiveProcessor = archiveProcessor
        self.filesManager = filesManager
        self.xcodeProjectPatcher = xcodeProjectPatcher
        self.dsymsExtractor = dsymsExtractor
        self.provisioningProfilesService = provisioningProfilesService
        self.config = config
    }

    private func makeBuilder() throws -> BuilderProtocol {
        let filesManager = FSManager(
            logger: logger,
            fileManager: FileManager.default
        )

        let builderConfig = Builder.Config(
            project: config.projectFile,
            scheme: config.scheme,
            derivedDataPath: config.derivedDataDir,
            logsPath: config.logsDir,
            configuration: nil,
            xcodebuildFormatterCommand: config.xcodebuildFormatterCommand
        )

        let logPathFactory = LogPathFactory(filesManager: filesManager)

        let xcodebuildCommand = XcodebuildCommandProducer(isUseRosetta: config.isUseRosetta)

        return Builder(
            filesManager: filesManager,
            logPathFactory: logPathFactory,
            shell: shell,
            logger: logger,
            timeMeasurer: TimeMeasurer(logger: logger),
            xcodebuildCommand: xcodebuildCommand,
            config: builderConfig
        )
    }

    /// - Returns: path to exported `.ipa`.
    public func run() throws -> (ipaPath: AbsolutePath, dsymsZipPath: AbsolutePath) {
        let date = Date().full_custom
        let rootDir = try config.archivesDir.appending(path: date)
        let archivePath = try rootDir.appending(path: "\(config.scheme)-\(config.buildConfiguration).xcarchive")
        let exportedIpaPath = try rootDir.appending(path: "exported").appending(path: config.ipaName)
        let dsymsZipName = archivePath.lastComponent.deletingExtension.string + ".dSYM.zip"
        let dsymsZipPath = try archivePath.deletingLastComponent.appending(path: dsymsZipName)

        // Update provisioning profile
        let profiles = try config.provisionProfiles.mapValues {
            try provisioningProfilesService.findProvisioningProfile(named: $0).profile
        }

        //		try xcodeProjectPatcher.setProvisionProfile(
        //			xcodeprojPath: config.projectFile,
        //			schemeName: config.scheme,
        //			configurationName: config.buildConfiguration,
        //			profileUUID: provisionProfile.UUID,
        //			profileName: provisionProfile.Name
        //		)

        // Create .xcarchive
        let builder = try makeBuilder()
        try builder.archive(
            buildConfiguration: config.buildConfiguration,
            archivePath: archivePath
        )

        // Export ipa from .xcarchive
        var exportConfig = XCArchiveExportOptions()
        exportConfig.compileBitcode = config.compileBitcode
        exportConfig.method = config.exportMethod
        exportConfig.manageAppVersionAndBuildNumber = config.manageAppVersionAndBuildNumber
        exportConfig.signingStyle = profiles.isEmpty ? .automatic : .manual
        exportConfig.provisioningProfiles = profiles.isEmpty ? nil : profiles.mapValues(\.UUID)
        //		exportConfig.provisioningProfiles = [
        //			provisionProfile.applicationBundleID: provisionProfile.UUID
        //		]
        try archiveProcessor.exportArchive(
            archivePath: archivePath,
            config: exportConfig,
            exportedIpaPath: exportedIpaPath
        )

        // Extract dsyms zip archive
        try dsymsExtractor.extractDsyms(xcarchivePath: archivePath, dsymsZipPath: dsymsZipPath)

        return (ipaPath: exportedIpaPath, dsymsZipPath: dsymsZipPath)
    }
}
