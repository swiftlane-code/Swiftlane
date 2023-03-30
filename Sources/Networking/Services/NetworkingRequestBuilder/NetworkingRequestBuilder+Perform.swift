//

import Combine
import Foundation

public extension NetworkingRequestBuilder {
    // MARK: - Perform with progress

    /// Create publisher of request's response data.
    func performWithProgress() -> AnyPublisher<NetworkingProgressOrResponse, NetworkingError> {
        progressAndResponse()
    }

    /// Create publisher of request's response data decoded as json to `T`.
    /// - Returns: Response specific deserializer. If `nil` is passed then NetworkClient's deserializer is used.
    func performWithProgress<T: Decodable>(
        deserializer: DeserializerProtocol? = nil
    ) -> AnyPublisher<ProgressOrResult<NetworkingProgress, T>, NetworkingError> {
        progressAndResponse()
            .tryMap {
                switch $0 {
                case let .progress(progress):
                    return .progress(progress)
                case let .result(response):
                    return .result(try (deserializer ?? self.deserializer).deseriaize(T.self, from: response.data))
                }
            }
            .mapError { NetworkingError(error: $0) }
            .eraseToAnyPublisher()
    }

    /// Create publisher of request's response raw data.
    func performWithProgress(
    ) -> AnyPublisher<ProgressOrResult<NetworkingProgress, Data>, NetworkingError> {
        progressAndResponse()
            .map {
                switch $0 {
                case let .progress(progress):
                    return .progress(progress)
                case let .result(response):
                    return .result(response.data)
                }
            }
            .eraseToAnyPublisher()
    }

    /// Create publisher of request's response data decoded as raw `String`.
    func performWithProgress(
    ) -> AnyPublisher<ProgressOrResult<NetworkingProgress, String>, NetworkingError> {
        progressAndResponse()
            .tryMap {
                switch $0 {
                case let .progress(progress):
                    return .progress(progress)
                case let .result(response):
                    guard let string = String(data: response.data, encoding: .utf8) else {
                        throw NetworkingError.unableToDecodeResponseMessage(
                            response: response,
                            message: "Unable to decode String from data using utf8 encoding."
                        )
                    }
                    return .result(string)
                }
            }
            .mapError { NetworkingError(error: $0) }
            .eraseToAnyPublisher()
    }

    /// Create publisher of request's response ignoring response body data.
    func performWithProgress() -> AnyPublisher<ProgressOrResult<NetworkingProgress, Void>, NetworkingError> {
        progressAndResponse()
            .map {
                switch $0 {
                case let .progress(progress):
                    return .progress(progress)
                case .result:
                    return .result(())
                }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Drop progress publisher

    /// Create publisher of request's response data.
    func perform() -> AnyPublisher<NetworkingResponse, NetworkingError> {
        performWithProgress().compactMap(\.result).eraseToAnyPublisher()
    }

    /// Create publisher of request's response data decoded as json to `T`.
    /// - Returns: Response specific deserializer. If `nil` is passed then NetworkClient's deserializer is used.
    func perform<T: Decodable>(deserializer: DeserializerProtocol? = nil) -> AnyPublisher<T, NetworkingError> {
        performWithProgress(deserializer: deserializer).compactMap(\.result).eraseToAnyPublisher()
    }

    /// Create publisher of request's response raw data.
    func perform() -> AnyPublisher<Data, NetworkingError> {
        performWithProgress().compactMap(\.result).eraseToAnyPublisher()
    }

    /// Create publisher of request's response data decoded as raw `String`.
    func perform() -> AnyPublisher<String, NetworkingError> {
        performWithProgress().compactMap(\.result).eraseToAnyPublisher()
    }

    /// Create publisher of request's response ignoring response body data.
    func perform() -> AnyPublisher<Void, NetworkingError> {
        performWithProgress().compactMap(\.result).eraseToAnyPublisher()
    }
}
