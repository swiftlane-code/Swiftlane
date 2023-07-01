//

import AppStoreConnectAPI
import AppStoreConnectJWT
import Foundation
import Provisioning
import Simulator
import SwiftlaneCore
import Xcodebuild
import Yams

public class BuildAppCommandRunner: CommandRunnerProtocol {
    private func build(
        params: BuildAppCommandParamsAccessing,
        paths: PathsFactoring,
        logger _: Logging
    ) throws {
        let builderConfig = Builder.Config(
            project: paths.projectFile,
            scheme: params.scheme,
            derivedDataPath: paths.derivedDataDir,
            logsPath: paths.logsDir,
            configuration: nil,
            xcodebuildFormatterCommand: paths.xcodebuildFormatterCommand
        )
        let buildTask = TasksFactory.makeBuildAppTask(
            builderConfig: builderConfig,
            buildForTesting: params.buildForTesting,
            buildDestination: .genericIOSDevice,
            isUseRosetta: params.rosettaOption.isUseRosetta
        )
        try buildTask.run()
    }

    public func run(
        params: BuildAppCommandParamsAccessing,
        commandConfig _: Void,
        sharedConfig: SharedConfigData,
        logger: Logging
    ) throws {
        try build(params: params, paths: sharedConfig.paths, logger: logger)
    }
}
