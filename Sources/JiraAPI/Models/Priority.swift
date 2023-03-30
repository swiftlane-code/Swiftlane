//

import Foundation

public struct Priority: Codable {
    public let name: String
    public let id: String
    public let linkString: String

    enum CodingKeys: String, CodingKey {
        case name, id
        case linkString = "self"
    }
}
