//

import Combine
import Foundation

public struct NetworkingRequest: CustomStringConvertible {
    public let baseURL: URL
    public let route: String
    public let method: HTTPMethod
    public var headers: [String: String] = [:]
    public var queryItems: [String: Any] = [:]
    public var body: Data?
    public var timeout: TimeInterval?

    public var description: String {
        let loggedBody = body.map { String(data: $0, encoding: .utf8) ?? $0.description }
        return "NetworkingRequest:\n" + [
            "baseURL: \(baseURL.description.quoted)",
            "route: \(route.quoted)",
            "fullURL: \(buildURLRequest(logger: nil).url?.absoluteString ?? "nil")",
            "method: \(method.rawValue.quoted)",
            "headers: \(headers.mapValues { _ in "<header value is not logged>" }.asPrettyJSON())",
            "queryItems: \(queryItems)",
            "body: \(loggedBody?.quoted ?? "nil")",
            "timeout: \(timeout?.description ?? "nil")",
        ].joined(separator: "\n").addPrefixToAllLines("\t")
    }
}
