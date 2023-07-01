
import Foundation
import Git
import GitLabAPI
import Guardian
import Networking
import Simulator
import SwiftlaneCore
import Xcodebuild
import Yams

public struct UploadGitLabPackageCommandRunner: CommandRunnerProtocol {
    public func verifyConfigs(
        params _: UploadGitLabPackageCommandParamsAccessing,
        commandConfig _: Void,
        sharedConfig _: SharedConfigData,
        logger: Logging
    ) throws -> Bool {
        let _ = try GitLabAPIClient(logger: logger)
        return true
    }

    public func run(
        params: UploadGitLabPackageCommandParamsAccessing,
        commandConfig _: Void,
        sharedConfig _: SharedConfigData,
        logger _: Logging
    ) throws {
        let taskConfig = UploadGitLabPackageTask.Config(
            projectID: params.projectID,
            packageName: params.packageName,
            packageVersion: params.packageVersion,
            file: params.file,
            uploadedFileName: params.uploadedFileName,
            timeoutSeconds: params.timeoutSeconds
        )

        let task = try TasksFactory.makeUploadGitLabPackageTask(taskConfig: taskConfig)

        try task.run()
    }
}
