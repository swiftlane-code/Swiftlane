//

import ArgumentParser
import Foundation
import SwiftlaneCore

public protocol GuardianCheckAuthorCommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }
}

/// CLI command to run Guardian after build.
public struct GuardianCheckAuthorCommand: ParsableCommand, GuardianCheckAuthorCommandParamsAccessing {
    public static var configuration = CommandConfiguration(
        commandName: "guardian-check-author",
        abstract: "Check that author has set a custom avatar and their name is correct. Also checks author's name in MR commits."
    )

    @OptionGroup public var sharedConfigOptions: SharedConfigOptions

    @Option(help: "Path to config.yml of this command.")
    public var config: AbsolutePath

    public init() {}

    public mutating func run() throws {
        GuardianCheckAuthorCommandRunner().run(self, sharedConfigOptions: sharedConfigOptions, commandConfigPath: config)
    }
}
