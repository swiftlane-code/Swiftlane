//

import Foundation

public extension JSONEncoder {
    static var snakeCaseConverting: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}
