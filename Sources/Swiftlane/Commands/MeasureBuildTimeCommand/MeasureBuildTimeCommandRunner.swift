//

import Foundation
import Simulator
import SwiftlaneCore
import Yams

public class MeasureBuildTimeCommandRunner: CommandRunnerProtocol {
    public func run(
        params: MeasureBuildTimeCommandParamsAccessing,
        commandConfig _: Void,
        sharedConfig: SharedConfigData,
        logger: Logging
    ) throws {
        let sigIntHandler = SigIntHandler(logger: logger)
        let xcodeChecker = XcodeChecker()

        let filesManager = FSManager(
            logger: logger,
            fileManager: FileManager.default
        )

        let shell = ShellExecutor(
            sigIntHandler: sigIntHandler,
            logger: logger,
            xcodeChecker: xcodeChecker,
            filesManager: filesManager
        )

        let runtimesMiner = RuntimesMiner(shell: shell)
        let simulatorProvider = SimulatorProvider(
            runtimesMiner: runtimesMiner,
            shell: shell,
            logger: logger
        )

        let task = MeasureBuildTimeTask(
            simulatorProvider: simulatorProvider,
            logger: logger,
            shell: shell,
            projectFile: sharedConfig.paths.projectFile,
            derivedDataDir: sharedConfig.paths.derivedDataDir,
            logsDir: sharedConfig.paths.logsDir,
            scheme: params.scheme,
            deviceModel: params.deviceModel,
            osVersion: params.osVersion,
            iterations: params.iterations,
            buildForTesting: params.buildForTesting,
            isUseRosetta: params.rosettaOption.isUseRosetta,
            xcodebuildFormatterPath: sharedConfig.paths.xcodebuildFormatterPath
        )

        try task.run()
    }
}
