//

import ArgumentParser
import Foundation

public protocol GuardianInitialNoteCommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }
}

public struct GuardianInitialNoteCommand: ParsableCommand, GuardianInitialNoteCommandParamsAccessing {
    public static var configuration = CommandConfiguration(
        commandName: "guardian-initial-note",
        abstract: "Run Guardian to take the first place in Merge Request comments."
    )

    @OptionGroup public var sharedConfigOptions: SharedConfigOptions

    public init() {}

    public mutating func run() throws {
        GuardianInitialNoteCommandRunner().run(self, sharedConfigOptions: sharedConfigOptions)
    }
}
