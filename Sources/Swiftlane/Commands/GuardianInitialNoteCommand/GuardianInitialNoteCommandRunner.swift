//

import Foundation
import Git
import GitLabAPI
import Guardian
import SwiftlaneCore

public struct GuardianInitialNoteCommandRunner: CommandRunnerProtocol {
    public func run(
        params _: GuardianInitialNoteCommandParamsAccessing,
        commandConfig _: Void,
        sharedConfig _: SharedConfigData,
        logger: Logging
    ) throws {
        let environmentValueReader = EnvironmentValueReader()

        let gitlabCIEnvironmentReader = GitLabCIEnvironmentReader(
            environmentValueReading: environmentValueReader
        )

        let mergeRequestReporter = MergeRequestReporter(
            logger: logger,
            gitlabApi: try GitLabAPIClient(logger: logger),
            gitlabCIEnvironment: gitlabCIEnvironmentReader,
            reportFactory: MergeRequestReportFactory(),
            publishEmptyReport: false
        )

        let task = GuardianInitialNoteTask(
            logger: logger,
            mergeRequestReporter: mergeRequestReporter,
            gitlabCIEnvironmentReader: gitlabCIEnvironmentReader
        )

        try task.run()
    }
}
