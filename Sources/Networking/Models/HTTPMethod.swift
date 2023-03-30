//

import Foundation

public enum HTTPMethod: String, Codable, Equatable {
    case get = "GET"
    case put = "PUT"
    case patch = "PATCH"
    case post = "POST"
    case delete = "DELETE"
}
