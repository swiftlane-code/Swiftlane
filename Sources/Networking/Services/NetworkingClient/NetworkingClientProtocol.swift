//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol NetworkingClientProtocol: AnyObject {
    /// Headers to include in each request.
    /// > Some of them may be overriden with per-request headers in case of key conflict.
    var commonHeaders: [String: String] { get set }

    /// Default timeout for all requests.
    /// > May be overriden by timout specified for a specific request.
    var timeout: TimeInterval { get set }

    /// Called before performing request. You can implement custom behaviour to modify the request.
    var willPerformRequest: ((inout NetworkingRequest) -> Void)? { get set }

    /// Level of logs for logger.
    var logLevel: LoggingLevel { get set }

    /// Create builder for GET request.
    func get(_ route: String) -> NetworkingRequestBuilder

    /// Create builder for PUT request.
    func put(_ route: String) -> NetworkingRequestBuilder

    /// Create builder for PATCH request.
    func patch(_ route: String) -> NetworkingRequestBuilder

    /// Create builder for POST request.
    func post(_ route: String) -> NetworkingRequestBuilder

    /// Create builder for DELETE request.
    func delete(_ route: String) -> NetworkingRequestBuilder
}
