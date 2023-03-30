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

    /// Use ``logLevel``. Kept alive for backward compatibility. TODO: Remove it later.
    @Flag(
        name: .customLong("verbose"),
        help: "Enable verbose log level. \("Deprecated".yellow), use --log-level instead."
    )
    public var __verbose: Bool = false

    @Option(help: "Path to file which will contain verbose logs.")
    public var verboseLogfile: AbsolutePath?

    @Flag(help: "Only verify configs and exit.")
    public var onlyVerifyConfigs: Bool = false

    public var resolvedLogLevel: LogLevelOption {
        if __verbose {
            return .verbose
        }
        return logLevel
    }

    public init() {}

    public func validate() throws {
        if __verbose {
            print("Please do not use --verbose option. Use --log-level instead.".lightYellow)
        }
        if __verbose, ProcessInfo.processInfo.arguments.contains("--log-level") {
            let msg = "Specify either --verbose or --log-level <level>".lightRed
            print(msg)
            throw ValidationError("Specify either --verbose or --log-level <level>")
        }
    }
}
