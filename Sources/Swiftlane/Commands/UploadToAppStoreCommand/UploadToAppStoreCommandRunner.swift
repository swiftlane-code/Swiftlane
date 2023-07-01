//

import AppStoreConnectAPI
import AppStoreConnectJWT
import Foundation
import Provisioning
import Simulator
import SwiftlaneCore
import Xcodebuild
import Yams

public class UploadToAppStoreTask {
    private let uploader: AppStoreConnectIPAUploading

    public init(uploader: AppStoreConnectIPAUploading) {
        self.uploader = uploader
    }

    func upload(ipaPath: AbsolutePath, using uploader: AppStoreConnectIPAUploaderType) throws {
        try self.uploader.upload(
            ipaPath: ipaPath,
            using: uploader
        )
    }
}

public class UploadToAppStoreCommandRunner: CommandRunnerProtocol {
    private func uploadIPA(
        params: UploadToAppStoreCommandParamsAccessing,
        paths: PathsFactoring,
        logger _: Logging
    ) throws {
        let task = try TasksFactory.makeUploadToAppStoreTask(
            authKeyPath: params.authKeyPath,
            authKeyIssuerID: params.authKeyIssuerID,
            paths: paths
        )

        try task.upload(
            ipaPath: params.ipaPath,
            using: params.uploadTool
        )
    }

    public func run(
        params: UploadToAppStoreCommandParamsAccessing,
        commandConfig _: Void,
        sharedConfig: SharedConfigData,
        logger: Logging
    ) throws {
        try uploadIPA(params: params, paths: sharedConfig.paths, logger: logger)
    }
}
