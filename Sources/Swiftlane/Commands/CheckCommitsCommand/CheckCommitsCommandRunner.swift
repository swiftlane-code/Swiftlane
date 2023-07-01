
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
    public func run(
        params: CheckCommitsCommandParamsAccessing,
        commandConfig: CheckCommitsCommandConfig,
        sharedConfig _: SharedConfigData
    ) throws {
        let checkerConfig = CommitsChecker.Config(
            projectDir: params.sharedConfigOptions.projectDir,
            commitsForCheck: commandConfig.commitsForCheck.map { .init(name: $0.name, commits: $0.commits) }
        )

        let task = try TasksFactory.makeCheckCommitsTask(checkerConfig: checkerConfig)

        try task.run()
    }
}
