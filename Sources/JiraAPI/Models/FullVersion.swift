//

import Foundation

public struct FullVersion: Codable, Hashable {
    public let linkString: String
    public let id: String
    public let name: String
    public let archived: Bool
    public let released: Bool
    public let startDate: Date?
    public let releaseDate: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, archived, released, startDate, releaseDate
        case linkString = "self"
    }
}
