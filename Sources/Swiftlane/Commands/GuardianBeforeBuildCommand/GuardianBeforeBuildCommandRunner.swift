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
        let environmentValueReader: EnvironmentValueReading = DependenciesFactory.resolve()
        let filesManager: FSManaging = DependenciesFactory.resolve()

        let expandedBlockingConfigPath = try environmentValueReader.expandVariables(
            in: commandConfig.expiringTODOs.blockingConfigPath
        )

        let expiringToDoBlockingConfig: ExpiringToDoBlockingConfig = try filesManager.decode(
            try AbsolutePath(expandedBlockingConfigPath),
            decoder: YAMLDecoder()
        )

        let task = try TasksFactory.makeGuardianBeforeBuildTask(
            projectDir: params.sharedConfigOptions.projectDir,
            expiringToDoBlockingConfig: expiringToDoBlockingConfig,
            commandConfig: commandConfig,
            sharedConfig: sharedConfig
        )

        try task.run()
    }
}
