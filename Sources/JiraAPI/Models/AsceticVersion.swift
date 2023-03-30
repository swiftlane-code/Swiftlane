//

import Foundation

public struct AsceticVersion: Codable, Hashable {
    public init(name: String) {
        self.name = name
    }

    public let name: String

    enum CodingKeys: String, CodingKey {
        case name
    }
}

extension AsceticVersion: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(name: value)
    }
}
