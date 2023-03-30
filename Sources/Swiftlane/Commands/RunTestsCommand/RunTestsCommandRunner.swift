import Foundation
import Simulator
import SwiftlaneCore
import Yams

public struct RunTestsCommandConfig: Decodable {
    public let scheme: String
    public let deviceModel: String
    public let osVersion: String
    public let simulatorsCount: UInt
    public let testPlan: String?
    public let useMultiScan: Bool
}

public struct RunTestsCommandRunner: CommandRunnerProtocol {
    public func run(
        params: RunTestsCommandParamsAccessing,
        commandConfig: RunTestsCommandConfig,
        sharedConfig: SharedConfigData,
        logger: Logging
    ) throws {
        let simulatorsCount = params.simCount ?? commandConfig.simulatorsCount
        guard 1 ... 10 ~= simulatorsCount else {
            logger.error("--sim-count value is allowed to be in range 1...10. Passed value: \(simulatorsCount).")
            Exitor().exit(with: 1)
            return
        }

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

        let useMultiScan = params.useMultiScan ?? commandConfig.useMultiScan

        let config = RunTestsTask.Config(
            projectDir: params.sharedConfigOptions.projectDir,
            projectFile: sharedConfig.paths.projectFile,
            scheme: params.scheme ?? commandConfig.scheme,
            deviceModel: params.deviceModel ?? commandConfig.deviceModel,
            osVersion: params.osVersion ?? commandConfig.osVersion,
            simulatorsCount: simulatorsCount,
            testPlan: params.testPlan ?? commandConfig.testPlan,
            derivedDataDir: sharedConfig.paths.derivedDataDir,
            testRunsDerivedDataDir: sharedConfig.paths.testRunsDerivedDataDir,
            logsDir: sharedConfig.paths.logsDir,
            resultsDir: sharedConfig.paths.resultsDir,
            mergedXCResultPath: sharedConfig.paths.mergedXCResult,
            mergedJUnitPath: sharedConfig.paths.mergedJUnit,
            testWithoutBuilding: useMultiScan,
            useMultiScan: useMultiScan,
            isUseRosetta: params.rosettaOption.isUseRosetta,
            xcodebuildFormatterPath: sharedConfig.paths.xcodebuildFormatterPath,
            testingTimeout: params.testingTimeout
        )

        let task = RunTestsTask(
            simulatorProvider: simulatorProvider,
            logger: logger,
            shell: shell,
            exitor: Exitor(),
            config: config
        )

        try task.run()
    }
}
