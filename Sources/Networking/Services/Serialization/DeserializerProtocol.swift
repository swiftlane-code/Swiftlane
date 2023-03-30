//

import Foundation

public protocol DeserializerProtocol {
    func deseriaize<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}
