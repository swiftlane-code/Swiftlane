//

import Combine
import Foundation
import Networking

/// Creating and manipulating pipelines.
public extension GitLabAPIClient {
    func createPipeline(
        projectId: Int,
        bodyModel: CreatePipeline
    ) -> AnyPublisher<Pipeline, NetworkingError> {
        client
            .post("projects/\(projectId)/pipeline")
            .with(body: bodyModel)
            .perform()
    }
}
