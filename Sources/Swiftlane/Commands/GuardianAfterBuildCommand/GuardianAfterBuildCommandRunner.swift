//

import Foundation
import Git
import GitLabAPI
import Guardian
import SwiftlaneCore
import Yams

public struct GuardianAfterBuildCommandRunner: CommandRunnerProtocol {
    public func run(
        params: GuardianAfterBuildCommandParamsAccessing,
        commandConfig: GuardianAfterBuildCommandConfig,
        sharedConfig: SharedConfigData,
        logger _: Logging
    ) throws {
        let task = try TasksFactory.makeGuardianAfterBuildTask(
            projectDir: params.sharedConfigOptions.projectDir,
            commandConfig: commandConfig,
            sharedConfig: sharedConfig,
            unitTestsExitCode: params.unitTestsExitCode
        )

        try task.run()
    }
}
