//

import Foundation
import Networking

public final class JiraAPISerializer: SerializerProtocol {
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .deferredToDate
        encoder.keyEncodingStrategy = .useDefaultKeys
        return encoder
    }()

    public init() {}

    public func serialize<T>(_ object: T) throws -> Data where T: Encodable {
        try encoder.encode(object)
    }
}
