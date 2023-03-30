//

import GitLabAPI
import SwiftlaneCore

public extension GitLabAPIClient {
    /// - Parameters:
    ///   - accessTokenHeaderKey: if you are using `CI_JOB_TOKEN` then set this to `"JOB-TOKEN"` instead of `"PRIVATE-TOKEN"`.
    convenience init(
        logger: Logging,
        logLevel: LoggingLevel = .silent,
        environmentReader: EnvironmentValueReading = EnvironmentValueReader(),
        baseURLEnvKey: ShellEnvKeyRepresentable = ShellEnvKey.GITLAB_API_ENDPOINT,
        accessTokenEnvKey: ShellEnvKeyRepresentable = ShellEnvKey.PROJECT_ACCESS_TOKEN,
        accessTokenHeaderKey: String = "PRIVATE-TOKEN"
    ) throws {
        self.init(
            baseURL: try environmentReader.url(baseURLEnvKey),
            accessToken: try environmentReader.string(accessTokenEnvKey),
            accessTokenHeaderKey: accessTokenHeaderKey,
            logLevel: logLevel,
            logger: logger
        )
    }
}
