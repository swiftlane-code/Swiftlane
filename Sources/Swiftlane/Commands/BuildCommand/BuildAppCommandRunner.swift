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
        paths: PathsFactoring
    ) throws {
        let builderConfig = Builder.Config(
            project: paths.projectFile,
            scheme: params.scheme,
            derivedDataPath: paths.derivedDataDir,
            logsPath: paths.logsDir,
            configuration: params.buildConfiguration,
            xcodebuildFormatterCommand: paths.xcodebuildFormatterCommand
        )
        let buildTask = TasksFactory.makeBuildAppTask(
            builderConfig: builderConfig,
            buildForTesting: params.buildForTesting,
            buildDestination: .genericIOSDevice
        )
        try buildTask.run()
    }

    public func run(
        params: BuildAppCommandParamsAccessing,
        commandConfig _: Void,
        sharedConfig: SharedConfigData
    ) throws {
        try build(params: params, paths: sharedConfig.paths)
    }
}
