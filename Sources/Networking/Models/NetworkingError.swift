//

import Foundation

/// Networking error model.
public enum NetworkingError: Error, LocalizedError, CustomStringConvertible {
    case notHTTPResponse(URLResponse)
    case badStatusCode(response: NetworkingResponse)
    case unableToDecodeResponse(response: NetworkingResponse, error: Error)
    case unableToDecodeResponseMessage(response: NetworkingResponse, message: String)
    case unableToEncodeRequestQueryItems(queryItems: Any, error: Error)
    case encodableQueryItemsCantBeConvertedToDictionary(queryItems: Any)
    case unableToEncodeRequestBody(body: Any, error: Error)
    case error(underlying: Error)

    public init(error: Error) {
        if let error = error as? NetworkingError {
            self = error
            return
        }
        self = .error(underlying: error)
    }

    public var description: String {
        switch self {
        case let .notHTTPResponse(response):
            return "response object is not a HTTPResponse: \(String(reflecting: response))"

        case let .badStatusCode(response):
            return "badStatusCode: \(response)"

        case let .unableToDecodeResponse(response, error):
            return "unableToDecodeResponse: \(response), error: \(error)"

        case let .unableToDecodeResponseMessage(response, message):
            return "unableToDecodeResponseMessage: \(response), message: \(message)"

        case let .unableToEncodeRequestQueryItems(queryItems, error):
            return "unableToEncodeRequestQueryItems: \(queryItems), error: \(error)"

        case let .unableToEncodeRequestBody(body, error):
            return "unableToEncodeRequestBody: \(body), error: \(error)"

        case let .encodableQueryItemsCantBeConvertedToDictionary(queryItems):
            return "encodableQueryItemsCantBeConverted to [String:Any]: \(queryItems)"

        case let .error(underlying):
            return "wrappedError: \(underlying)"
        }
    }

    public var errorDescription: String? {
        description
    }
}
