//

import ArgumentParser
import Foundation
import SwiftlaneCore

public struct BuildNumberCommandOptions: ParsableArguments {
    public init() {}
}

public struct BuildNumberCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "build-number",
        abstract: "Work with build number of project targets.",
        subcommands: [
            BuildNumberSetCommand.self,
        ]
    )

    public init() {}
}
