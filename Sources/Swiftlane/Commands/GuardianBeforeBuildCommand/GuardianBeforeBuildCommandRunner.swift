//

import Foundation
import Git
import GitLabAPI
import Guardian
import SwiftlaneCore
import Yams

public struct GuardianBeforeBuildCommandRunner: CommandRunnerProtocol {
    public func run(
        params: GuardianBeforeBuildCommandParamsAccessing,
        commandConfig: GuardianBeforeBuildCommandConfig,
        sharedConfig: SharedConfigData
    ) throws {
        let task = try TasksFactory.makeGuardianBeforeBuildTask(
            projectDir: params.sharedConfigOptions.projectDir,
            commandConfig: commandConfig,
            sharedConfig: sharedConfig
        )

        try task.run()
    }
}
