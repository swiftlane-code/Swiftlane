
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

public struct ChangeVersionCommandRunner: CommandRunnerProtocol {
    public init() {}

    public func run(
        params: ChangeVersionCommandParamsAccessing,
        commandConfig: ChangeVersionCommandConfig,
        sharedConfig: SharedConfigData,
        logger _: Logging
    ) throws {
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

        let gitlabCIEnvironmentReader: GitLabCIEnvironmentReading = DependenciesFactory.resolve()

        let taskConfig = ChangeVersionTask.Config(
            sourceBranchName: try gitlabCIEnvironmentReader.string(.CI_COMMIT_REF_NAME),
            bumpStrategy: bumpStrategy
        )

        let versioningConfig = ProjectVersioningService.Config(
            projectDir: params.sharedConfigOptions.projectDir,
            commitMessagePrefix: commandConfig.prefixUpdateCommitMessage,
            committeeName: sharedConfig.values.gitAuthorName,
            committeeEmail: sharedConfig.values.gitAuthorEmail,
            infoPlistPath: commandConfig.infoPlistPath
        )

        let task = try TasksFactory.makeChangeVersionTask(
            versioningConfig: versioningConfig,
            taskConfig: taskConfig
        )

        try task.run()
    }
}
