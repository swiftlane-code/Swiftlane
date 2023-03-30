//

import Foundation

public struct NetworkingResponse: CustomStringConvertible {
    public let request: NetworkingRequest
    public let urlRequest: URLRequest
    public let urlResponse: HTTPURLResponse
    public let data: Data

    public var status: ResponseStatus {
        .make(for: urlResponse.statusCode)
    }

    public var description: String {
        "NetworkingResponse:\n" + [
            "\(request)",
            "Status code: \(status.rawValue) (\(status))",
            "Response body: " + (String(data: data, encoding: .utf8)?.quoted ?? data.description),
        ].joined(separator: "\n").addPrefixToAllLines("\t")
    }
}
