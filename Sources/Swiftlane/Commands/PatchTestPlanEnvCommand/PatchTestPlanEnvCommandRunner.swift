import Foundation
import Guardian
import Simulator
import SwiftlaneCore
import Xcodebuild
import Yams

public struct PatchTestPlanEnvCommandConfig: Decodable {
    public let patchVariablesWithNames: [StringMatcher]
    public let testPlanSearchExcludedDirs: [RelativePath]?
    public let testPlanSearchIncludedDirs: [RelativePath]
}

public struct PatchTestPlanEnvCommandRunner: CommandRunnerProtocol {
    public func run(
        params: PatchTestPlanEnvCommandParamsAccessing,
        commandConfig: PatchTestPlanEnvCommandConfig,
        sharedConfig _: SharedConfigData,
        logger: Logging
    ) throws {
        let filesManager = FSManager(logger: logger, fileManager: FileManager.default)

        let environmentValueReader = EnvironmentValueReader()

        let testPlanPatcher = XCTestPlanPatcher(
            logger: logger,
            filesManager: filesManager,
            environmentReader: environmentValueReader
        )

        let config = PatchTestPlanEnvTaskConfig(
            testPlanName: params.testPlanName,
            projectDir: params.sharedConfigOptions.projectDir,
            patchVariablesWithNames: commandConfig.patchVariablesWithNames,
            testPlanSearchExcludedDirs: commandConfig.testPlanSearchExcludedDirs?.map {
                params.sharedConfigOptions.projectDir.appending(path: $0)
            } ?? [],
            testPlanSearchIncludedDirs: commandConfig.testPlanSearchIncludedDirs.map {
                params.sharedConfigOptions.projectDir.appending(path: $0)
            }
        )

        let task = PatchTestPlanEnvTask(
            logger: logger,
            filesManager: filesManager,
            environmentReader: environmentValueReader,
            patcher: testPlanPatcher,
            config: config
        )

        try task.run()
    }
}
