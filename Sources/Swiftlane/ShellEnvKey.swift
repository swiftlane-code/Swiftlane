//

import SwiftlaneCore

public enum ShellEnvKey: String {
    case CI
    /// Typically user password is provided this way on CI
    case CI_USER_PASSWORD
    case GITLAB_API_ENDPOINT
    case PROJECT_ACCESS_TOKEN
    case JIRA_API_TOKEN
    case JIRA_API_ENDPOINT
    case GIT_AUTHOR_EMAIL
    case GITLAB_GROUP_DEV_TEAM_ID_TO_FETCH_MEMBERS
    case CODESIGNING_CERTS_REPO_URL
    case CODESIGNING_CERTS_REPO_PASS
}

extension ShellEnvKey: ShellEnvKeyRepresentable {
    public var asShellEnvKey: String {
        rawValue
    }
}
