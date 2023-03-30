//

import Foundation

public struct Status: Codable {
    public let description: String
    public let id: String
    public let name: String
    public let linkString: String

    enum CodingKeys: String, CodingKey {
        case description, id, name
        case linkString = "self"
    }
}
