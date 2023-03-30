//

import Foundation

public extension NetworkingDumper {
    struct DumpEntry: Codable {
        public let request: CodableNetworkingRequest
        public let responseBody: String
        public let responseCode: Int
        public let loggerRequestUUID: UUID

        public init(
            response: NetworkingResponse,
            requestUUID: UUID
        ) {
            request = CodableNetworkingRequest(request: response.request)
            responseBody = String(data: response.data, encoding: .utf8) ?? "<unable to decode data text>"
            responseCode = response.urlResponse.statusCode
            loggerRequestUUID = requestUUID
        }
    }
}

public extension NetworkingDumper {
    struct CodableNetworkingRequest: Codable, Equatable {
        public let baseURL: URL
        public let route: String
        public let method: HTTPMethod
        public let absoluteURL: URL
        public let body: String?
        public let timeout: TimeInterval?

        public init(request: NetworkingRequest) {
            baseURL = request.baseURL
            route = request.route
            absoluteURL = request.buildURLRequest(logger: nil).url?.absoluteURL ?? request.baseURL
            method = request.method
            body = request.body.flatMap { String(data: $0, encoding: .utf8) }
            timeout = request.timeout
        }
    }
}
