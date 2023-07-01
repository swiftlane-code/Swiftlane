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
    public func run(
        params: UploadToAppStoreCommandParamsAccessing,
        commandConfig _: Void,
        sharedConfig: SharedConfigData
    ) throws {
        let task = try TasksFactory.makeUploadToAppStoreTask(
            authKeyPath: params.authKeyPath,
            authKeyIssuerID: params.authKeyIssuerID,
            paths: sharedConfig.paths
        )

        try task.upload(
            ipaPath: params.ipaPath,
            using: params.uploadTool
        )
    }
}
