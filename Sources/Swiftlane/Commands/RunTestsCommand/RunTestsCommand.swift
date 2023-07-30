//

import ArgumentParser
import Foundation
import SwiftlaneCore

public protocol RunTestsCommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }
    var configPath: AbsolutePath { get }
    var testPlan: String? { get }
    var scheme: String? { get }
    var deviceModel: String? { get }
    var osVersion: String? { get }
    var simCount: UInt? { get }
    var useMultiScan: Bool? { get }
    var testingTimeout: TimeInterval { get }
}

/// CLI command to run SMRunTests.
public struct RunTestsCommand: ParsableCommand, RunTestsCommandParamsAccessing {
    public static var configuration = CommandConfiguration(
        commandName: "run-tests",
        abstract: "Run UI- or Unit- tests."
    )

    @OptionGroup public var sharedConfigOptions: SharedConfigOptions

    @Option(
        name: [.customLong("config")],
        help: "Path to config.yml"
    )
    public var configPath: AbsolutePath

    @Option(help: "Test plan to be used (should be included in the scheme).")
    public var testPlan: String?

    @Option(help: "Project scheme.")
    public var scheme: String?

    @Option(help: "Name of original simulator to be cloned.")
    public var deviceModel: String?

    @Option(help: "OS version of original simulator to be cloned.")
    public var osVersion: String?

    @Option(help: "Number of simulators for parallel testing.")
    public var simCount: UInt?

    @Option(help: "Separate build and test steps. Run tests in parallel in chunks separated for multiple simulators.")
    public var useMultiScan: Bool?

    @Option(help: "Testing timeout in seconds.")
    public var testingTimeout: TimeInterval = 3600

    public init() {}

    public mutating func run() throws {
        RunTestsCommandRunner().run(self, sharedConfigOptions: sharedConfigOptions, commandConfigPath: configPath)
    }
}
