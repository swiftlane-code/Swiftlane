//

import Combine
import Foundation
import Networking

public extension JiraAPIClient {
    /// Change issue status.
    func transitionIssue(issueKey: String, transition: Transition) -> AnyPublisher<Void, NetworkingError> {
        client
            .post("issue/\(issueKey)/transitions")
            .with(body: [
                "transition": transition,
            ])
            .perform()
    }

    func setFixVersionsField(issueKey: String, full: [FullVersion]) -> AnyPublisher<Void, NetworkingError> {
        client
            .put("issue/\(issueKey)")
            .with(body: [
                "fields": [
                    "fixVersions": full,
                ],
            ])
            .perform()
    }

    func setFixVersionsField(issueKey: String, ascetic: [AsceticVersion]) -> AnyPublisher<Void, NetworkingError> {
        client
            .put("issue/\(issueKey)")
            .with(body: [
                "fields": [
                    "fixVersions": ascetic,
                ],
            ])
            .perform()
    }

    /// Note: wrap value like this `AnyEncodable("new value")` or `AnyEncodable(String?.none)`.
    func setField(issueKey: String, fieldKey: String, value: AnyEncodable) -> AnyPublisher<Void, NetworkingError> {
        client
            .put("issue/\(issueKey)")
            .with(body: [
                "fields": [
                    fieldKey: value,
                ],
            ])
            .perform()
    }

    func createVersion(name: String, projectId: String) -> AnyPublisher<Void, NetworkingError> {
        client
            .post("version")
            .with(body: [
                "name": name,
                "projectId": projectId,
            ])
            .perform()
    }

    /// Set `labels` field of an issue.
    /// - Parameters:
    ///   - labels: target labels. Current value of issue's labels will be overwritten.
    func updateLabels(issueKey: String, labels: [String]) -> AnyPublisher<Void, NetworkingError> {
        client
            .put("issue/\(issueKey)")
            .with(body: [
                "fields": [
                    "labels": labels,
                ],
            ])
            .perform()
    }

    func addComment(issueKey: String, text: String) -> AnyPublisher<Void, NetworkingError> {
        client
            .post("issue/\(issueKey)/comment")
            .with(body: [
                "body": text,
            ])
            .perform()
    }
}
