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
    public func run(
        params _: GuardianCheckAuthorCommandParamsAccessing,
        commandConfig: GuardianCheckAuthorCommandConfig,
        sharedConfig _: SharedConfigData
    ) throws {
        let task = try TasksFactory.makeGuardianCheckAuthorTask(commandConfig: commandConfig)

        try task.run()
    }
}
