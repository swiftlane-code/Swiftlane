//

import AppStoreConnectAPI
import AppStoreConnectJWT
import FirebaseAPI
import Foundation
import Git
import Provisioning
import Simulator
import SwiftlaneCore
import Xcodebuild
import Yams

public class ArchiveAndExportIPACommandRunner: CommandRunnerProtocol {
    private func archiveAndExportIPA(
        params: ArchiveAndExportIPACommandParamsAccessing,
        exportMethod: XCArchiveExportOptions.ExportMethod,
        paths: PathsFactoring,
        logger: Logging
    ) throws -> AbsolutePath {
        let archiveTaskConfig = ArchiveAndExportIPATaskConfig(
            projectFile: paths.projectFile,
            derivedDataDir: paths.derivedDataDir,
            logsDir: paths.logsDir,
            archivesDir: paths.archivesDir,
            scheme: params.scheme,
            buildConfiguration: params.buildConfiguration,
            ipaName: params.ipaName,
            provisionProfiles: params.provisioningProfileNamesForBundleIDs,
            exportMethod: exportMethod,
            compileBitcode: params.compileBitcode,
            manageAppVersionAndBuildNumber: nil,
            isUseRosetta: params.rosettaOption.isUseRosetta,
            xcodebuildFormatterPath: paths.xcodebuildFormatterPath
        )
        let task = try ArchiveAndExportIPATaskAssembly().assemble(taskConfig: archiveTaskConfig, logger: logger)
        return try task.run().ipaPath
    }

    public func run(
        params: ArchiveAndExportIPACommandParamsAccessing,
        commandConfig _: Void,
        sharedConfig: SharedConfigData,
        logger: Logging
    ) throws {
        let exportMethod = try XCArchiveExportOptions.ExportMethod(
            rawValue: params.exportMethod
        ).unwrap(
            errorDescription: "Export method can be one of \(XCArchiveExportOptions.ExportMethod.allCases.description)"
        )

        _ = try archiveAndExportIPA(
            params: params,
            exportMethod: exportMethod,
            paths: sharedConfig.paths,
            logger: logger
        )
    }
}
