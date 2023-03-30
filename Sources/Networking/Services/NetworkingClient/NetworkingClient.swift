//

import Combine
import Foundation
import SwiftlaneCore

public class NetworkingClient {
    /// Different routes will be appended for specific requests to the end of `baseURL`.
    public let baseURL: URL

    /// Headers to include in each request.
    /// > Some of them may be overriden with per-request headers in case of key conflict.
    public var commonHeaders = [String: String]()

    /// Default timeout for all requests.
    /// > May be overriden by timout specified for a specific request.
    public var timeout: TimeInterval

    /// Called before performing request. You can implement custom behaviour to modify the request.
    public var willPerformRequest: ((inout NetworkingRequest) -> Void)?

    /// URLSession instance to perform request with.
    private var session: URLSession

    /// Level of logs for logger.
    public var logLevel: LoggingLevel {
        get { logger?.logLevel ?? .silent }
        set { logger?.logLevel = newValue }
    }

    /// Encoder to encode Encodable requests.
    let serializer: SerializerProtocol
    /// Decoder to decode Decodable requests.
    let deserializer: DeserializerProtocol

    /// Logger instance.
    private let logger: NetworkingLoggerProtocol?
    /// Dumper instance.
    private let dumper: NetworkingDumperProtocol?

    /// Initializes an instance of NetworkingClient.
    /// - Parameters:
    ///   - baseURL: Different routes will be appended for specific requests to the end of `baseURL`.
    ///   - configuration: Configuration of url session.
    ///   - timeout: Default timeout for all requests. May be overriden by timout specified for a specific request.
    ///   - serializer: Encoder to encode Encodable requests.
    ///   - deserializer: Decoder to decode Decodable requests.
    public init(
        baseURL: URL,
        configuration: URLSessionConfiguration = .default,
        timeout: TimeInterval = 60,
        serializer: SerializerProtocol = JSONSerializer(encoder: .snakeCaseConverting),
        deserializer: DeserializerProtocol = JSONDeserializer(decoder: .snakeCaseConverting),
        logger: NetworkingLoggerProtocol? = nil,
        dumper: NetworkingDumperProtocol? = nil
    ) {
        self.baseURL = baseURL
        self.timeout = timeout
        self.serializer = serializer
        self.deserializer = deserializer
        self.logger = logger
        self.dumper = dumper
        session = URLSession(configuration: configuration)
    }

    /// Merge `request.headers` with `self.commonHeaders` and create response publisher.
    /// Errors are mapped to `NetworkingError`.
    /// - Parameter request: Request model.
    /// - Returns: Publisher of response.
    func perform(request: NetworkingRequest) -> AnyPublisher<NetworkingProgressOrResponse, NetworkingError> {
        var request = request
        request.headers = commonHeaders.merging(request.headers) { $1 }
        request.timeout = request.timeout ?? timeout
        willPerformRequest?(&request)
        return publisher(for: request)
    }

    /// Create response publisher.
    /// Response status code is validated to be in range `200..<300`
    /// otherwise a `NetworkingError.badStatusCode` would be produced.
    ///
    /// > Request and response can be logged.
    ///
    /// - Parameter request: Request model.
    /// - Returns: Publishers of progress and response.
    private func publisher(for request: NetworkingRequest) -> AnyPublisher<NetworkingProgressOrResponse, NetworkingError> {
        let urlRequest = request.buildURLRequest(logger: logger)
        let uuid = UUID()

        return session.dataTaskPublisherWithProgress(for: urlRequest)
            .handleEvents(receiveSubscription: { _ in
                self.logger?.log(client: self, request: request, urlRequest: urlRequest, uuid: uuid)
            })
            .tryMap { dataTaskProgress -> NetworkingProgressOrResponse in
                switch dataTaskProgress {
                case let .progress(dataTask):
                    let progress = NetworkingProgress(
                        fractionCompleted: dataTask.progress.fractionCompleted,
                        completedBytes: (dataTask.progress.userInfo[.byteCompletedCountKey] as? Int64) ?? -1,
                        totalBytes: (dataTask.progress.userInfo[.byteTotalCountKey] as? Int64) ?? -1
                    )
                    return .progress(progress)
                case let .result(data, response):
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw NetworkingError.notHTTPResponse(response)
                    }

                    let response = NetworkingResponse(
                        request: request,
                        urlRequest: urlRequest,
                        urlResponse: httpResponse,
                        data: data
                    )

                    self.logger?.log(client: self, response: response, requestUUID: uuid)
                    self.dumper?.dump(response: response, requestUUID: uuid)

                    guard response.status.responseType == .success else {
                        throw NetworkingError.badStatusCode(response: response)
                    }

                    return .result(response)
                }
            }
            .mapError {
                NetworkingError(error: $0)
            }
            .eraseToAnyPublisher()
    }
}
