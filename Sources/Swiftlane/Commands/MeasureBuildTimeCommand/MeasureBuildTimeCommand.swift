//

import ArgumentParser
import Foundation
import SwiftlaneCore

public protocol MeasureBuildTimeCommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }
    var rosettaOption: RosettaGlobalOption { get }
    var projectName: Path { get }
    var scheme: String { get }
    var deviceModel: String { get }
    var osVersion: String { get }
    var iterations: Int { get }
    var buildForTesting: Bool { get }
}

public struct MeasureBuildTimeCommand: ParsableCommand, MeasureBuildTimeCommandParamsAccessing {
    public static var configuration = CommandConfiguration(
        commandName: "measure-build-time",
        abstract: "Measure build time in N iterations."
    )

    @OptionGroup public var sharedConfigOptions: SharedConfigOptions
    @OptionGroup public var rosettaOption: RosettaGlobalOption

    @Option(help: "Project name.")
    public var projectName: Path

    @Option(help: "Project scheme.")
    public var scheme: String

    @Option(help: "Name of original simulator to be cloned.")
    public var deviceModel: String = "iPhone 11"

    @Option(help: "OS version of original simulator to be cloned.")
    public var osVersion: String = "14.5"

    @Option(help: "Count of build iterations.")
    public var iterations: Int

    @Option(help: "Build for testing. Set to `true` to build Unit/UI Tests.")
    public var buildForTesting: Bool

    public init() {}

    public mutating func run() throws {
        MeasureBuildTimeCommandRunner().run(self, sharedConfigOptions: sharedConfigOptions)
    }
}
