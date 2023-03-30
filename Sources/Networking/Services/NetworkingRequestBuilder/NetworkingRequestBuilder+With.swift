//

import Combine
import Foundation

public extension NetworkingRequestBuilder {
    /// Set request headers.
    /// > Only the last call of this method will have effect.
    func with(headers: [String: String]) -> Self {
        var builder = self
        builder.request.headers = headers
        return builder
    }

    /// Set request query items.
    /// > Only the last call of this method will have effect.
    func with(queryItems: [String: Any]) -> Self {
        var builder = self
        builder.request.queryItems = queryItems
        return builder
    }

    /// Set request query items.
    /// Be careful what you are passing here as it will be internally converted to dictionary.
    /// > Only the last call of this method will have effect.
    func with(queryItemsEncodable: Encodable) -> Self {
        var builder = self
        builder.encodableQueryItems = queryItemsEncodable
        builder.request.queryItems = [:]
        return builder
    }

    /// Set request body.
    /// > Only the last call of
    /// ```
    /// func with(body: Data)
    /// ```
    /// or
    /// ```
    /// func with<T: Encodable>(body: T)
    /// ```
    /// will have effect.
    func with(body: Data) -> Self {
        var builder = self
        builder.request.body = body
        builder.encodableBody = nil
        return builder
    }

    /// Set request body.
    /// > Only the last call of
    /// ```
    /// func with(body: Data)
    /// ```
    /// or
    /// ```
    /// func with<T: Encodable>(body: T)
    /// ```
    /// will have effect.
    func with<T: Encodable>(body: T) -> Self {
        var builder = self
        builder.encodableBody = body
        builder.request.body = nil
        return builder
    }

    /// Set request timeout.
    /// > Only the last call of this method will have effect.
    func with(timeout: TimeInterval) -> Self {
        var builder = self
        builder.request.timeout = timeout
        return builder
    }
}
