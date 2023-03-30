
import Foundation
import Git
import GitLabAPI
import Guardian
import Simulator
import SwiftlaneCore
import Yams

public struct CheckCommitsCommandConfig: Decodable {
    public struct CommitsForCheck: Decodable {
        public let name: StringMatcher
        public let commits: [String]
    }

    public let commitsForCheck: [CommitsForCheck]
}

public struct CheckCommitsCommandRunner: CommandRunnerProtocol {
    public func verifyConfigs(
        params _: CheckCommitsCommandParamsAccessing,
        commandConfig _: CheckCommitsCommandConfig,
        sharedConfig _: SharedConfigData,
        logger: Logging
    ) throws -> Bool {
        let _ = try GitLabAPIClient(logger: logger)
        return true
    }

    public func run(
        params: CheckCommitsCommandParamsAccessing,
        commandConfig: CheckCommitsCommandConfig,
        sharedConfig: SharedConfigData,
        logger: Logging
    ) throws {
        let environmentValueReader = EnvironmentValueReader()
        let gitlabCIEnvironmentReader = GitLabCIEnvironmentReader(environmentValueReading: environmentValueReader)

        let sigIntHandler = SigIntHandler(logger: logger)
        let xcodeChecker = XcodeChecker()

        let filesManager = FSManager(
            logger: logger,
            fileManager: FileManager.default
        )

        let shell: ShellExecuting = ShellExecutor(
            sigIntHandler: sigIntHandler,
            logger: logger,
            xcodeChecker: xcodeChecker,
            filesManager: filesManager
        )

        let git = Git(
            shell: shell,
            filesManager: filesManager,
            diffParser: GitDiffParser(logger: logger)
        )

        let mergeRequestReporter = MergeRequestReporter(
            logger: logger,
            gitlabApi: try GitLabAPIClient(logger: logger),
            gitlabCIEnvironment: gitlabCIEnvironmentReader,
            reportFactory: MergeRequestReportFactory(),
            publishEmptyReport: true
        )

        let reporter = CommitsCheckerEnReporter(
            reporter: mergeRequestReporter
        )

        let checkerConfig = CommitsChecker.Config(
            projectDir: params.sharedConfigOptions.projectDir,
            commitsForCheck: commandConfig.commitsForCheck.map { .init(name: $0.name, commits: $0.commits) }
        )

        let checker = CommitsChecker(
            logger: logger,
            git: git,
            gitlabCIEnvironment: gitlabCIEnvironmentReader,
            reporter: reporter,
            config: checkerConfig
        )

        let task = CheckCommitsTask(
            checker: checker,
            reporter: mergeRequestReporter
        )

        let projectPath = try gitlabCIEnvironmentReader.string(.CI_PROJECT_PATH)
        guard sharedConfig.values.availableProjects.isMatching(string: projectPath) else {
            logger.warn("Skipped run task about project with path \(projectPath.quoted)")
            return
        }

        try task.run()
    }
}
