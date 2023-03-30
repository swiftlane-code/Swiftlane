//

import Foundation

public extension Encodable {
    func eraseToAnyEncodable() -> AnyEncodable {
        AnyEncodable(self)
    }
}

public class AnyEncodable: Encodable {
    private let object: Any
    private let encode: (Encoder) throws -> Void

    public init<T: Encodable>(_ object: T) {
        self.object = object
        encode = object.encode(to:)
    }

    public func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
