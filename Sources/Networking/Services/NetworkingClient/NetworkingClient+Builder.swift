//

import Combine
import Foundation

extension NetworkingClient: NetworkingClientProtocol {
    public func get(_ route: String) -> NetworkingRequestBuilder {
        .init(
            method: .get,
            baseURL: baseURL,
            route: route,
            serializer: serializer,
            deserializer: deserializer,
            perform: perform(request:)
        )
    }

    public func put(_ route: String) -> NetworkingRequestBuilder {
        .init(
            method: .put,
            baseURL: baseURL,
            route: route,
            serializer: serializer,
            deserializer: deserializer,
            perform: perform(request:)
        )
    }

    public func patch(_ route: String) -> NetworkingRequestBuilder {
        .init(
            method: .patch,
            baseURL: baseURL,
            route: route,
            serializer: serializer,
            deserializer: deserializer,
            perform: perform(request:)
        )
    }

    public func post(_ route: String) -> NetworkingRequestBuilder {
        .init(
            method: .post,
            baseURL: baseURL,
            route: route,
            serializer: serializer,
            deserializer: deserializer,
            perform: perform(request:)
        )
    }

    public func delete(_ route: String) -> NetworkingRequestBuilder {
        .init(
            method: .delete,
            baseURL: baseURL,
            route: route,
            serializer: serializer,
            deserializer: deserializer,
            perform: perform(request:)
        )
    }
}
