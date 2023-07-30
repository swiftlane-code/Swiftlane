//

import ArgumentParser
import Foundation
import SwiftlaneCore

public protocol BuildAppCommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }

    var scheme: String { get }
    var buildConfiguration: String { get }
    var buildForTesting: Bool { get }
}

public struct BuildAppCommand: ParsableCommand, BuildAppCommandParamsAccessing {
    public static var configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Build scheme for generic iOS device."
    )

    @OptionGroup public var sharedConfigOptions: SharedConfigOptions

    @Option(help: "Scheme to build.")
    public var scheme: String

    @Option(help: "Build configuration. Common ones are 'Debug' and 'Release'.")
    public var buildConfiguration: String

    @Option(help: "Build for testing or running.")
    public var buildForTesting: Bool

    public init() {}

    public mutating func run() throws {
        BuildAppCommandRunner().run(self, sharedConfigOptions: sharedConfigOptions)
    }
}
