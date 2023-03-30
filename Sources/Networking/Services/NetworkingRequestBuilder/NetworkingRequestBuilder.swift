//

import Combine
import Foundation

/// Builder of request model.
public struct NetworkingRequestBuilder {
    /// Buildable request model.
    var request: NetworkingRequest

    /// Encoder to encode Encodable requests.
    let serializer: SerializerProtocol
    /// Decoder to decode Decodable requests.
    let deserializer: DeserializerProtocol

    var encodableQueryItems: Encodable?

    var encodableBody: Encodable?

    /// Closure which should produce `NetworkingResponse` publisher for request model.
    private let performClosure: (NetworkingRequest) -> AnyPublisher<NetworkingProgressOrResponse, NetworkingError>

    /// Initialize new instance of builder.
    /// - Parameters:
    ///   - method: HTTP method.
    ///   - baseURL: Different routes will be appended for specific requests to the end of `baseURL`.
    ///   - route: part of url to be appended to `baseURL`.
    ///   - serializer: Encoder to encode Encodable requests.
    ///   - deserializer: Decoder to decode Decodable requests.
    ///   - perform: Closure which should produce `NetworkingResponse` publisher for request model.
    init(
        method: HTTPMethod,
        baseURL: URL,
        route: String,
        serializer: SerializerProtocol,
        deserializer: DeserializerProtocol,
        perform: @escaping (NetworkingRequest) -> AnyPublisher<NetworkingProgressOrResponse, NetworkingError>
    ) {
        request = .init(baseURL: baseURL, route: route, method: method)
        self.serializer = serializer
        self.deserializer = deserializer
        performClosure = perform
    }

    private func buildRequest() throws -> NetworkingRequest {
        var request = request

        if let encodableQueryItems = encodableQueryItems {
            do {
                let data = try JSONEncoder().encode(encodableQueryItems.eraseToAnyEncodable())
                guard let dictionary = try JSONSerialization.jsonObject(
                    with: data,
                    options: .allowFragments
                ) as? [String: Any] else {
                    throw NetworkingError.encodableQueryItemsCantBeConvertedToDictionary(
                        queryItems: encodableQueryItems
                    )
                }
                request.queryItems = dictionary
            } catch {
                throw NetworkingError.unableToEncodeRequestQueryItems(
                    queryItems: encodableQueryItems,
                    error: error
                )
            }
        }

        if let encodableBody = encodableBody {
            do {
                request.body = try serializer.serialize(encodableBody.eraseToAnyEncodable())
            } catch {
                throw NetworkingError.unableToEncodeRequestBody(
                    body: encodableBody,
                    error: error
                )
            }
        }

        return request
    }

    /// Encode request body if needed and perform request.
    func progressAndResponse() -> AnyPublisher<NetworkingProgressOrResponse, NetworkingError> {
        do {
            let request = try buildRequest()
            return performClosure(request)
        } catch {
            return Fail(error: NetworkingError(error: error)).eraseToAnyPublisher()
        }
    }
}
