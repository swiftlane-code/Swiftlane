//

import Foundation

public extension DecodingError {
    var description: String {
        switch self {
        case let .typeMismatch(_, value):
            return "typeMismatch error: \(value.debugDescription)  \(localizedDescription)"
        case let .valueNotFound(_, value):
            return "valueNotFound error: \(value.debugDescription)  \(localizedDescription)"
        case let .keyNotFound(_, value):
            return "keyNotFound error: \(value.debugDescription)  \(localizedDescription)"
        case let .dataCorrupted(key):
            return "dataCorrupted error at: \(key)  \(localizedDescription)"
        default:
            return "decoding error: \(localizedDescription)"
        }
    }
}
