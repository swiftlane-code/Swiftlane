//

import Combine
import Foundation
import Networking

/// Working with pipelines.
public extension GitLabAPIClient {
    /// Load pipeline info.
    func pipeline(
        projectId: Int,
        pipelineId: Int
    ) -> AnyPublisher<Pipeline, NetworkingError> {
        client
            .get("projects/\(projectId)/pipelines/\(pipelineId)")
            .perform()
    }
}
