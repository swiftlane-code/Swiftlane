//

import Foundation
import SwiftlaneCore
import Xcodebuild

public class BuildNumberSetCommandRunner: CommandRunnerProtocol {
    public func verifyConfigs(
        params _: BuildNumberSetCommandParamsAccessing,
        commandConfig _: Void,
        sharedConfig _: SharedConfigData,
        logger _: Logging
    ) throws -> Bool {
        true
    }

    public func run(
        params: BuildNumberSetCommandParamsAccessing,
        commandConfig _: Void,
        sharedConfig: SharedConfigData,
        logger: Logging
    ) throws {
        let filesManager = FSManager(
            logger: logger,
            fileManager: FileManager.default
        )

        let shell = ShellExecutor(
            sigIntHandler: SigIntHandler(logger: logger),
            logger: logger,
            xcodeChecker: XcodeChecker(),
            filesManager: filesManager
        )

        let projectPatcher = XcodeProjectPatcher(
            logger: logger,
            shell: shell,
            plistBuddyService: PlistBuddyService(shell: shell)
        )

        if params.buildSettings {
            try projectPatcher.setCurrentProjectVersion(
                xcodeprojPath: sharedConfig.paths.projectFile,
                value: params.buildNumber
            )
        }

        if params.infoPlist {
            try projectPatcher.setCFBundleVersion(
                xcodeprojPath: sharedConfig.paths.projectFile,
                value: params.buildNumber
            )
        }
    }
}
