//

import Foundation

public extension JSONDecoder {
    static var snakeCaseConverting: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
