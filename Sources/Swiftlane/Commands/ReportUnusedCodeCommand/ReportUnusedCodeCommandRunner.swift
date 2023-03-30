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

        let peripheryService = PeripheryService(shell: shell, filesManager: filesManager)

        let peripheryResultsFormatter = PeripheryResultsMarkdownFormatter(filesManager: filesManager)

        let taskConfig = ReportUnusedCodeTaskConfig(
            projectDir: params.sharedConfigOptions.projectDir,
            reportedFiles: params.reportedFile,
            ignoredTypesNames: params.ignoreTypeName,
            mattermostWebhookKey: params.mattermostWebhookKey,
            buildUsingPeriphery: params.build
        )

        let environmentReader = EnvironmentValueReader()
        let gitlabCIEnvironment = GitLabCIEnvironmentReader(environmentValueReading: environmentReader)

        let mattermostAPIClient = params.mattermostApiURL.map {
            MattermostAPIClient(baseURL: $0, logger: logger)
        }

        let task = ReportUnusedCodeTask(
            logger: logger,
            shell: shell,
            filesManager: filesManager,
            peripheryService: peripheryService,
            resultsFormatter: peripheryResultsFormatter,
            paths: sharedConfig.paths,
            gitlabCIEnvironment: gitlabCIEnvironment,
            mattermostAPIClient: mattermostAPIClient,
            config: taskConfig
        )

        try task.run()
    }
}
