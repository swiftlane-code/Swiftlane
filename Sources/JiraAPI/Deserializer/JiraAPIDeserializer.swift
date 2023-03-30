//

import Foundation
import Networking

public final class JiraAPIDeserializer: DeserializerProtocol {
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.yyyyMMdd_dashSeparated)
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }()

    public init() {}

    public func deseriaize<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        try Self.decoder.decode(type, from: data)
    }
}
