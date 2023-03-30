//

import Foundation

public extension ResponseStatus {
    var responseType: ResponseType {
        switch rawValue {
        case 100 ..< 200:
            return .informational

        case 200 ..< 300:
            return .success

        case 300 ..< 400:
            return .redirection

        case 400 ..< 500:
            return .clientError

        case 500 ..< 600:
            return .serverError

        default:
            return .undefined
        }
    }
}
