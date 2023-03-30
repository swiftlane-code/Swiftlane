//

import Foundation
import Git
import GitLabAPI
import Guardian
import SwiftlaneCore

public struct GuardianCheckAuthorCommandConfig: Decodable {
    public let validGitLabUserName: DescriptiveStringMatcher
    public let validCommitAuthorName: DescriptiveStringMatcher
}

public struct GuardianCheckAuthorCommandRunner: CommandRunnerProtocol {
    public func verifyConfigs(
        params _: GuardianCheckAuthorCommandParamsAccessing,
        commandConfig _: GuardianCheckAuthorCommandConfig,
        sharedConfig _: SharedConfigData,
        logger: Logging
    ) throws -> Bool {
        let _ = try GitLabAPIClient(logger: logger)
        return true
    }

    public func run(
        params _: GuardianCheckAuthorCommandParamsAccessing,
        commandConfig: GuardianCheckAuthorCommandConfig,
        sharedConfig _: SharedConfigData,
        logger: Logging
    ) throws {
        let environmentValueReader = EnvironmentValueReader()

        let gitlabAPIClient = try GitLabAPIClient(logger: logger)

        let gitlabCIEnvironmentReader = GitLabCIEnvironmentReader(
            environmentValueReading: environmentValueReader
        )

        let mergeRequestReporter = MergeRequestReporter(
            logger: logger,
            gitlabApi: gitlabAPIClient,
            gitlabCIEnvironment: gitlabCIEnvironmentReader,
            reportFactory: MergeRequestReportFactory(),
            publishEmptyReport: true
        )

        let reporter = MergeRequestAuthorCheckerReporter(
            reporter: mergeRequestReporter
        )

        let mergeRequestAuthorChecker = MergeRequestAuthorChecker(
            reporter: reporter,
            gitlabApi: gitlabAPIClient,
            gitlabCIEnvironment: gitlabCIEnvironmentReader,
            validGitLabUserName: commandConfig.validGitLabUserName,
            validCommitAuthorName: commandConfig.validCommitAuthorName
        )

        let task = GuardianCheckAuthorTask(
            logger: logger,
            mergeRequestReporter: mergeRequestReporter,
            mergeRequestAuthorChecker: mergeRequestAuthorChecker,
            gitlabCIEnvironmentReader: gitlabCIEnvironmentReader
        )

        try task.run()
    }
}
