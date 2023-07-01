//

import Foundation
import Git
import Guardian
import MattermostAPI
import Provisioning
import Simulator
import SwiftlaneCore
import Xcodebuild
import Yams

public class ReportUnusedCodeCommandRunner: CommandRunnerProtocol {
    public func run(
        params: ReportUnusedCodeCommandParamsAccessing,
        commandConfig _: Void,
        sharedConfig: SharedConfigData,
        logger _: Logging
    ) throws {
        let taskConfig = ReportUnusedCodeTaskConfig(
            projectDir: params.sharedConfigOptions.projectDir,
            reportedFiles: params.reportedFile,
            ignoredTypesNames: params.ignoreTypeName,
            mattermostWebhookKey: params.mattermostWebhookKey,
            buildUsingPeriphery: params.build
        )

        let task = try TasksFactory.makeReportUnusedCodeTask(
            taskConfig: taskConfig,
            mattermostApiURL: params.mattermostApiURL,
            paths: sharedConfig.paths
        )

        try task.run()
    }
}
