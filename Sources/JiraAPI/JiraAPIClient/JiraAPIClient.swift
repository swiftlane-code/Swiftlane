//

import Combine
import Foundation
import Networking
import SwiftlaneCore

// sourcery: AutoMockable
public protocol JiraAPIClientProtocol {
    var requestTimeout: TimeInterval { get }

    func getProject(projectKey: String) -> AnyPublisher<Project, NetworkingError>
    func versions(projectKey: String) -> AnyPublisher<[FullVersion], NetworkingError>
    func loadDetailVersion(version: String) -> AnyPublisher<DetailVersion, NetworkingError>
    func search(jql: JiraJQL) -> AnyPublisher<SearchResult, NetworkingError>
    func loadIssue(issueKey: String) -> AnyPublisher<Issue, NetworkingError>
    func loadTransitions(issueKey: String) -> AnyPublisher<TransitionsResponse, NetworkingError>
    func transitionIssue(issueKey: String, transition: Transition) -> AnyPublisher<Void, NetworkingError>
    func setFixVersionsField(issueKey: String, ascetic: [AsceticVersion]) -> AnyPublisher<Void, NetworkingError>
    func setFixVersionsField(issueKey: String, full: [FullVersion]) -> AnyPublisher<Void, NetworkingError>
    /// Note: wrap value like this `AnyEncodable("new value")` or `AnyEncodable(String?.none)`.
    func setField(issueKey: String, fieldKey: String, value: AnyEncodable) -> AnyPublisher<Void, NetworkingError>
    func createVersion(name: String, projectId: String) -> AnyPublisher<Void, NetworkingError>
    func updateLabels(issueKey: String, labels: [String]) -> AnyPublisher<Void, NetworkingError>
    func addComment(issueKey: String, text: String) -> AnyPublisher<Void, NetworkingError>
}

public class JiraAPIClient: JiraAPIClientProtocol {
    let client: NetworkingClientProtocol

    public var requestTimeout: TimeInterval {
        client.timeout
    }

    public init(networkingClient: NetworkingClientProtocol) {
        client = networkingClient
    }
}

public extension JiraAPIClient {
    convenience init(
        baseURL: URL,
        accessToken: String,
        requestsTimeout: TimeInterval,
        logger: Logging,
        logLevel: LoggingLevel = .silent
    ) {
        let client = NetworkingClient(
            baseURL: baseURL,
            serializer: JiraAPISerializer(),
            deserializer: JiraAPIDeserializer(),
            logger: NetworkingLogger(
                logLevel: logLevel,
                logger: logger
            )
        )

        client.timeout = requestsTimeout
        client.commonHeaders = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json",
        ]

        self.init(networkingClient: client)
    }
}
