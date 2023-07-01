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
        logger _: Logging
    ) throws {
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

        let task = try TasksFactory.makePatchTestPlanEnvTask(config: config)

        try task.run()
    }
}
