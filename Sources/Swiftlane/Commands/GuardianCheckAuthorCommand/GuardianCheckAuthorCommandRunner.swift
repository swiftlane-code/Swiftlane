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
        return true
    }

    public func run(
        params _: GuardianCheckAuthorCommandParamsAccessing,
        commandConfig: GuardianCheckAuthorCommandConfig,
        sharedConfig _: SharedConfigData,
        logger _: Logging
    ) throws {
        let task = try TasksFactory.makeGuardianCheckAuthorTask(commandConfig: commandConfig)

        try task.run()
    }
}
