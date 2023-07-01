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
        logger _: Logging
    ) throws {
        let projectPatcher: XcodeProjectPatching = DependenciesFactory.resolve()

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
