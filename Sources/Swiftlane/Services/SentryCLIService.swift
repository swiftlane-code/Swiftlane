//

import Foundation
import SwiftlaneCore

public class SentryCLIService {
    private let logger: Logging
    private let shell: ShellExecuting

    private let sentryCLICommand: String
    private let sentryURL: String
    private let sentryAuthToken: SensitiveData<String>
    private let sentryORG: String
    private let sentryProject: String

    public init(
        logger: Logging,
        shell: ShellExecuting,
        sentryCLICommand: String = "sentry-cli",
        sentryURL: String,
        sentryAuthToken: SensitiveData<String>,
        sentryORG: String,
        sentryProject: String
    ) {
        self.logger = logger
        self.shell = shell
        self.sentryCLICommand = sentryCLICommand
        self.sentryURL = sentryURL
        self.sentryAuthToken = sentryAuthToken
        self.sentryORG = sentryORG
        self.sentryProject = sentryProject
    }

    public func upload(dsymsPaths: [AbsolutePath], timeout: TimeInterval, verbose: Bool) throws {
        try shell.run(
            [
                sentryCLICommand,
                "--url " + sentryURL.quoted,
                "--auth-token " + sentryAuthToken.sensitiveValue.quoted,
                "upload-dsym",
                "--org " + sentryORG.quoted,
                "--project " + sentryProject.quoted,
                "--force-foreground",
                "--log-level " + (verbose ? "debug" : "info"), // possible values: trace, debug, info, warn, error
            ] + dsymsPaths.map(\.string.quoted),
            log: .commandAndOutput(outputLogLevel: .info),
            maskSubstringsInLog: [sentryAuthToken.sensitiveValue],
            executionTimeout: timeout
        )
    }
}
