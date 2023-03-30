//

import Foundation
import SwiftlaneCore

public struct SharedConfigModel: Decodable {
    public let sharedValues: SharedConfigValues
    public let pathsConfig: PathsConfig
}

public struct SharedConfigValues: Decodable {
    /// e.g. `ABCD`.
    public let jiraProjectKey: String

    /// In seconds.
    public let jiraRequestsTimeout: TimeInterval

    public let gitAuthorName: String
    public let gitAuthorEmail: String

    public let availableProjects: [StringMatcher]

    private enum CodingKeys: String, CodingKey {
        case jiraProjectKey, jiraRequestsTimeout, gitAuthorName, availableProjects, gitAuthorEmail
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        jiraProjectKey = try container.decode(String.self, forKey: .jiraProjectKey)
        jiraRequestsTimeout = try container.decode(TimeInterval.self, forKey: .jiraRequestsTimeout)
        gitAuthorName = try container.decode(String.self, forKey: .gitAuthorName)
        availableProjects = try container.decode([StringMatcher].self, forKey: .availableProjects)

        let decodedGitAuthorEmail = try container.decodeIfPresent(String.self, forKey: .gitAuthorEmail)
        gitAuthorEmail = try decodedGitAuthorEmail ?? EnvironmentValueReader().string(ShellEnvKey.GIT_AUTHOR_EMAIL)
    }

    public init(
        jiraProjectKey: String,
        jiraRequestsTimeout: TimeInterval,
        gitAuthorName: String,
        gitAuthorEmail: String,
        availableProjects: [StringMatcher]
    ) {
        self.jiraProjectKey = jiraProjectKey
        self.jiraRequestsTimeout = jiraRequestsTimeout
        self.gitAuthorName = gitAuthorName
        self.gitAuthorEmail = gitAuthorEmail
        self.availableProjects = availableProjects
    }
}

/// For description of values see `PathsFactoring`.
public struct PathsConfig: Decodable {
    public let xclogparserJSONReportName: RelativePath

    public let xclogparserHTMLReportDirName: RelativePath

    public let mergedJUnitName: RelativePath

    public let mergedXCResultName: RelativePath?

    public let xccovFileName: RelativePath

    public let projectFile: RelativePath

    public let derivedDataDir: Path

    public let testRunsDerivedDataDir: Path

    public let logsDir: Path

    public let resultsDir: Path

    public let archivesDir: Path

    public let swiftlintConfigPath: Path

    public let swiftlintWarningsJsonsFolder: Path

    public let tempDir: Path

    public let xcodebuildFormatterPath: Path
}
