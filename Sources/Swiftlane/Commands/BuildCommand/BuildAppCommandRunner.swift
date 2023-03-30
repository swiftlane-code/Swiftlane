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
        logger: Logging
    ) throws {
        let builderConfig = Builder.Config(
            project: paths.projectFile,
            scheme: params.scheme,
            derivedDataPath: paths.derivedDataDir,
            logsPath: paths.logsDir,
            configuration: nil,
            xcodebuildFormatterPath: paths.xcodebuildFormatterPath
        )
        let buildTask = BuildAppTaskAssembly().assemble(
            paths: paths,
            builderConfig: builderConfig,
            buildForTesting: params.buildForTesting,
            buildDestination: .genericIOSDevice, // hardcode for now
            isUseRosetta: params.rosettaOption.isUseRosetta,
            logger: logger
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
