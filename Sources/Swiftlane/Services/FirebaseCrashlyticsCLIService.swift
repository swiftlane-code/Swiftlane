//

import Foundation
import SwiftlaneCore

public class FirebaseCrashlyticsCLIService {
    public enum App {
        case appID(String)
        case googleServiceInfoPlist(AbsolutePath)

        public var cliOption: String {
            switch self {
            case let .appID(appID):
                return "--app-id " + appID.quoted
            case let .googleServiceInfoPlist(path):
                return "--google-service-plist " + path.string.quoted
            }
        }
    }

    /// The platform for which the dSYM was compiled. Either: 'ios', 'mac', 'tvos'. Catalyst apps should be the 'mac' platform.
    public enum Platform {
        case ios
        case tvOS
        case mac
        case macCatalyst

        public var cliOption: String {
            let prefix = "--platform "
            switch self {
            case .ios:
                return prefix + "ios"
            case .tvOS:
                return prefix + "tvos"
            case .mac, .macCatalyst:
                return prefix + "mac"
            }
        }
    }

    private let logger: Logging
    private let shell: ShellExecuting

    private let binaryPath: AbsolutePath

    public init(
        logger: Logging,
        shell: ShellExecuting,
        binaryPath: AbsolutePath
    ) {
        self.logger = logger
        self.shell = shell
        self.binaryPath = binaryPath
    }

    public func uploadSymbols(
        for app: App,
        platform: Platform,
        dsymsPaths: [AbsolutePath],
        debug: Bool,
        timeout: TimeInterval
    ) throws {
        try shell.run(
            [
                binaryPath.string.quoted,
                app.cliOption,
                platform.cliOption,
                debug ? "--debug" : "",
                "--",
            ] + dsymsPaths.map(\.string.quoted),
            log: .commandAndOutput(outputLogLevel: .info),
            executionTimeout: timeout
        )
    }
}
