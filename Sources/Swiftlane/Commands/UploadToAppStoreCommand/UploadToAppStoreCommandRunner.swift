//

import AppStoreConnectAPI
import AppStoreConnectJWT
import Foundation
import Provisioning
import Simulator
import SwiftlaneCore
import Xcodebuild
import Yams

public class UploadToAppStoreCommandRunner: CommandRunnerProtocol {
    private func uploadIPA(
        params: UploadToAppStoreCommandParamsAccessing,
        paths: PathsFactoring,
        logger: Logging
    ) throws {
        let authKeyIDParser = AppStoreConnectAuthKeyIDParser()

        let filesManager = FSManager(
            logger: logger,
            fileManager: FileManager.default
        )

        let sigIntHandler = SigIntHandler(logger: logger)
        let xcodeChecker = XcodeChecker()

        let shell = ShellExecutor(
            sigIntHandler: sigIntHandler,
            logger: logger,
            xcodeChecker: xcodeChecker,
            filesManager: filesManager
        )

        let ipaUploader = AppStoreConnectIPAUploader(
            logger: logger,
            filesManager: filesManager,
            shell: shell,
            tokenGenerator: try AppStoreConnectTokenGenerator(
                filesManager: filesManager,
                authKeyIDParser: authKeyIDParser,
                jwtGenerator: AppStoreConnectJWTGenerator(),
                authKeyPath: params.authKeyPath,
                authKeyIssuerID: params.authKeyIssuerID.sensitiveValue
            ),
            authKeyIDParser: authKeyIDParser,
            config: .init(
                authKeyPath: params.authKeyPath,
                authKeyIssuerID: params.authKeyIssuerID.sensitiveValue,
                logFile: try paths.logsDir.appending(
                    path: "upload-to-appstore/\(params.ipaPath.lastComponent.string)_\(Date().full_custom).log"
                )
            )
        )

        try ipaUploader.upload(
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
