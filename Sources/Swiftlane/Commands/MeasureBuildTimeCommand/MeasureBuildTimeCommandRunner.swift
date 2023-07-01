//

import Foundation
import Simulator
import SwiftlaneCore
import Xcodebuild
import Yams

public class MeasureBuildTimeCommandRunner: CommandRunnerProtocol {
    public func run(
        params: MeasureBuildTimeCommandParamsAccessing,
        commandConfig _: Void,
        sharedConfig: SharedConfigData
    ) throws {
        let builderConfig = Builder.Config(
            project: sharedConfig.paths.projectFile,
            scheme: params.scheme,
            derivedDataPath: sharedConfig.paths.derivedDataDir,
            logsPath: sharedConfig.paths.logsDir,
            configuration: params.configuration,
            xcodebuildFormatterCommand: sharedConfig.paths.xcodebuildFormatterCommand
        )

        let config = MeasureBuildTimeTask.Config(
            deviceModel: params.deviceModel,
            osVersion: params.osVersion,
            iterations: params.iterations,
            buildForTesting: params.buildForTesting
        )

        let task = try TasksFactory.makeMeasureBuildTimeTask(builderConfig: builderConfig, config: config)

        try task.run()
    }
}
