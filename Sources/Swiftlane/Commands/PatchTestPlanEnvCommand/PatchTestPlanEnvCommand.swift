//

import ArgumentParser
import Foundation
import SwiftlaneCore

public protocol PatchTestPlanEnvCommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }
    var configPath: AbsolutePath { get }
    var testPlanName: String { get }
}

public struct PatchTestPlanEnvCommand: ParsableCommand, PatchTestPlanEnvCommandParamsAccessing {
    public static var configuration = CommandConfiguration(
        commandName: "patch-test-plan-env",
        abstract: "Patches environment variables in test plan according to current proccess environment."
    )

    @OptionGroup public var sharedConfigOptions: SharedConfigOptions

    @Option(
        name: [.customLong("config")],
        help: "Path to config.yml"
    )
    public var configPath: AbsolutePath

    @Option(help: "Test plan name without public extension (e.g. 'BaseTestPlan')")
    public var testPlanName: String

    public init() {}

    public mutating func run() throws {
        PatchTestPlanEnvCommandRunner().run(self, sharedConfigOptions: sharedConfigOptions, commandConfigPath: configPath)
    }
}
