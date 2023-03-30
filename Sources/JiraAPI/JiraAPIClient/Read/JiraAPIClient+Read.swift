//

import Combine
import Foundation
import Networking

public extension JiraAPIClient {
    /// Load info about project.
    func getProject(projectKey: String) -> AnyPublisher<Project, NetworkingError> {
        client
            .get("project/\(projectKey)")
            .perform()
    }

    /// Load release versions of a project.
    func versions(projectKey: String) -> AnyPublisher<[FullVersion], NetworkingError> {
        client
            .get("project/\(projectKey)/versions")
            .perform()
    }

    /// Load release version details.
    func loadDetailVersion(version: String) -> AnyPublisher<DetailVersion, NetworkingError> {
        client
            .get("version/\(version)")
            .with(queryItems: ["expand": "issuesstatus"])
            .perform()
    }

    func search(jql: JiraJQL) -> AnyPublisher<SearchResult, NetworkingError> {
        client
            .post("search")
            .with(body: JiraSearch(jql: jql.jqlString))
            .perform()
    }

    /// Load issue info.
    func loadIssue(issueKey: String) -> AnyPublisher<Issue, NetworkingError> {
        client
            .get("issue/\(issueKey)")
            .perform()
    }

    /// Load issue transitions.
    func loadTransitions(issueKey: String) -> AnyPublisher<TransitionsResponse, NetworkingError> {
        client
            .get("issue/\(issueKey)/transitions")
            .perform()
    }

    /// Load not-released version where `version.startDate < now < version.releaseDate`
    func currentNotReleasedVersion(projectKey: String) -> AnyPublisher<FullVersion?, NetworkingError> {
        versions(projectKey: projectKey)
            .map {
                if let current = $0
                    .filter({ !$0.released && $0.releaseDate != nil && $0.startDate != nil })
                    .first(where: { $0.startDate! ... $0.releaseDate! ~= Date() })
                {
                    return current
                }
                return nil
            }
            .eraseToAnyPublisher()
    }
}
