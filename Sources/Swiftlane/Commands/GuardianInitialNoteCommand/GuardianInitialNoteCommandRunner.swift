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
        logger _: Logging
    ) throws {
        let task = try TasksFactory.makeGuardianInitialNoteTask()

        try task.run()
    }
}
