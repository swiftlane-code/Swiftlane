//

import AppStoreConnectAPI
import AppStoreConnectJWT
import Foundation
import Provisioning
import Simulator
import SwiftlaneCore
import Xcodebuild
import Yams

public class SetProvisioningCommandRunner: CommandRunnerProtocol {
    private func updateProvisioning(
        params: SetProvisioningCommandParamsAccessing,
        paths: PathsFactoring,
        logger _: Logging
    ) throws {
        let taskConfig = SetProvisioningTaskConfig(
            xcodeprojPath: paths.projectFile,
            schemeName: params.scheme,
            buildConfigurationName: params.buildConfiguration,
            provisionProfileName: params.provisionProfileName
        )
        let updateProvisioningTask = TasksFactory.makeSetProvisioningTask(
            taskConfig: taskConfig
        )
        try updateProvisioningTask.run()
    }

    public func run(
        params: SetProvisioningCommandParamsAccessing,
        commandConfig _: Void,
        sharedConfig: SharedConfigData,
        logger: Logging
    ) throws {
        try updateProvisioning(params: params, paths: sharedConfig.paths, logger: logger)
    }
}
