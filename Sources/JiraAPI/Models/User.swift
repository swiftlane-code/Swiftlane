//

import Foundation

public struct User: Codable {
    public let key: String
    public let displayName: String
    public let emailAddress: String
    public let linkString: String

    enum CodingKeys: String, CodingKey {
        case key, displayName, emailAddress
        case linkString = "self"
    }
}
