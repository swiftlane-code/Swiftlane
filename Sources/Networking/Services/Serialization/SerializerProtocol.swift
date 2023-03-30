//

import Foundation

public protocol SerializerProtocol {
    func serialize<T: Encodable>(_ object: T) throws -> Data
}
