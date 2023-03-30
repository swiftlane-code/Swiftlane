//

import Foundation
import JiraAPI
import SwiftlaneCore

public extension JiraAPIClient {
    convenience init(
        requestsTimeout: TimeInterval,
        logger: Logging,
        logLevel: LoggingLevel = .silent,
        baseURLEnvKey: ShellEnvKeyRepresentable = ShellEnvKey.JIRA_API_ENDPOINT,
        accessTokenEnvKey: ShellEnvKeyRepresentable = ShellEnvKey.JIRA_API_TOKEN,
        environmentReader: EnvironmentValueReading = EnvironmentValueReader()
    ) throws {
        self.init(
            baseURL: try environmentReader.url(baseURLEnvKey),
            accessToken: try environmentReader.string(accessTokenEnvKey),
            requestsTimeout: requestsTimeout,
            logger: logger,
            logLevel: logLevel
        )
    }
}
