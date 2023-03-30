
import Foundation
import Git
import GitLabAPI
import Guardian
import Simulator
import SwiftlaneCore
import Xcodebuild
import Yams

public struct ChangeVersionCommandConfig: Decodable {
    public let infoPlistPath: RelativePath
    public let prefixUpdateCommitMessage: String
}

public struct ChangeVersionCommandRunner<GenericProjectVersionConverter>: CommandRunnerProtocol where
    GenericProjectVersionConverter: Initable & ProjectVersionConverting
{
    public init() {}

    public func run(
        params: ChangeVersionCommandParamsAccessing,
        commandConfig: ChangeVersionCommandConfig,
        sharedConfig: SharedConfigData,
        logger: Logging
    ) throws {
        let filesManager = FSManager(
            logger: logger,
            fileManager: FileManager.default
        )

        let shell = ShellExecutor(
            sigIntHandler: SigIntHandler(logger: logger),
            logger: logger,
            xcodeChecker: XcodeChecker(),
            filesManager: filesManager
        )

        let environmentValueReader = EnvironmentValueReader()
        let gitlabCIEnvironmentReader = GitLabCIEnvironmentReader(environmentValueReading: environmentValueReader)

        let bumpStrategy: ChangeVersionTask.Config.ChangeVersionStrategy = {
            switch params.action {
            case .bumpMajor:
                return .bumpMajor
            case .bumpMinor:
                return .bumpMinor
            case .bumpPatch:
                return .bumpPatch
            }
        }()

        let taskConfig = ChangeVersionTask.Config(
            projectDir: params.sharedConfigOptions.projectDir,
            sourceBranchName: try gitlabCIEnvironmentReader.string(.CI_COMMIT_REF_NAME),
            bumpStrategy: bumpStrategy,
            infoPlistPath: commandConfig.infoPlistPath,
            prefixUpdateCommitMessage: commandConfig.prefixUpdateCommitMessage,
            committeeName: sharedConfig.values.gitAuthorName,
            committeeEmail: sharedConfig.values.gitAuthorEmail
        )

        let git = Git(
            shell: shell,
            filesManager: filesManager,
            diffParser: GitDiffParser(logger: logger)
        )

        let projectService = GenericProjectVersionConverter()
        let projectPatcher = XcodeProjectPatcher(
            logger: logger,
            shell: shell,
            plistBuddyService: PlistBuddyService(shell: shell)
        )

        let versioningService = ProjectVersioningService(
            logger: logger,
            filesManager: filesManager,
            versionConverter: projectService,
            projectPatcher: projectPatcher,
            git: git,
            config: ProjectVersioningService.Config(
                projectDir: params.sharedConfigOptions.projectDir,
                commitMessagePrefix: commandConfig.prefixUpdateCommitMessage,
                committeeName: sharedConfig.values.gitAuthorName,
                committeeEmail: sharedConfig.values.gitAuthorEmail,
                infoPlistPath: commandConfig.infoPlistPath
            )
        )

        let task = ChangeVersionTask(
            logger: logger,
            versioningService: versioningService,
            config: taskConfig
        )

        let projectPath = try gitlabCIEnvironmentReader.string(.CI_PROJECT_PATH)
        guard sharedConfig.values.availableProjects.isMatching(string: projectPath) else {
            logger.warn("Skipped run task about project with path \(projectPath.quoted)")
            return
        }

        try task.run()
    }
}
