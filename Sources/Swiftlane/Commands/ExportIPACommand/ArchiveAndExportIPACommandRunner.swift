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
        paths: PathsFactoring
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
            xcodebuildFormatterCommand: paths.xcodebuildFormatterCommand
        )
        let task = TasksFactory.makeArchiveAndExportIPATask(
            taskConfig: archiveTaskConfig
        )
        return try task.run().ipaPath
    }

    public func run(
        params: ArchiveAndExportIPACommandParamsAccessing,
        commandConfig _: Void,
        sharedConfig: SharedConfigData
    ) throws {
        let exportMethod = try XCArchiveExportOptions.ExportMethod(
            rawValue: params.exportMethod
        ).unwrap(
            errorDescription: "Export method can be one of \(XCArchiveExportOptions.ExportMethod.allCases.description)"
        )

        _ = try archiveAndExportIPA(
            params: params,
            exportMethod: exportMethod,
            paths: sharedConfig.paths
        )
    }
}
