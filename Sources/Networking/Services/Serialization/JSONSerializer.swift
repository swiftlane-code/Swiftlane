//

import Foundation

public final class JSONSerializer: SerializerProtocol {
    private let encoder: JSONEncoder

    public init(encoder: JSONEncoder) {
        self.encoder = encoder
    }

    public func serialize<T: Encodable>(_ object: T) throws -> Data {
        try encoder.encode(object)
    }
}
