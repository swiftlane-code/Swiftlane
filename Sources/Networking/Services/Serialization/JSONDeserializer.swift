//

import Foundation

public final class JSONDeserializer: DeserializerProtocol {
    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder) {
        self.decoder = decoder
    }

    public func deseriaize<T: Decodable>(_: T.Type, from data: Data) throws -> T {
        try decoder.decode(T.self, from: data)
    }
}
