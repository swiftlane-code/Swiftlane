//

public struct Transition: Codable {
    public let id: String
    public let name: String
    public let targetStatus: Status

    public init(
        id: String,
        targetStatus: Status,
        name: String = ""
    ) {
        self.id = id
        self.targetStatus = targetStatus
        self.name = name
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case targetStatus = "to"
    }

    enum EncodingKeys: String, CodingKey {
        case id
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: EncodingKeys.self)
        try container.encode(id, forKey: .id)
    }
}
