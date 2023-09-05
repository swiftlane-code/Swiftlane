//

import ArgumentParser
import Foundation
import SwiftlaneCore

public enum LogLevelOption: String, ExpressibleByArgument {
    case silent
    case error
    case warning
    case important
    case info
    case debug
    case verbose
}

public extension LoggingLevel {
    init(from option: LogLevelOption) {
        switch option {
        case .verbose:
            self = .verbose
        case .debug:
            self = .debug
        case .info:
            self = .info
        case .warning:
            self = .warning
        case .error:
            self = .error
        case .silent:
            self = .silent
        case .important:
            self = .important
        }
    }
}

public struct SharedConfigOptions: ParsableArguments {
    @Option(help: "Project dir path.")
    public var projectDir: AbsolutePath

    @Option(
        name: [.customLong("shared-config")],
        help: "Path to shared-config.yml"
    )
    public var sharedConfigPath: AbsolutePath

    @OptionGroup public var commonOptions: CommonOptions

    public init() {}
}

public struct CommonOptions: ParsableArguments {
    @Option(help: "Logging level.")
    public var logLevel: LogLevelOption = .info

    @Option(help: "Path to file which will contain verbose logs (always verbose regardless --log-level option).")
    public var verboseLogfile: AbsolutePath?

    public init() {}
}
