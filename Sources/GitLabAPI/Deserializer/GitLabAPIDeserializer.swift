//

import Foundation
import Networking
import SwiftlaneCore

public final class GitLabAPIDeserializer: DeserializerProtocol {
    /// Date parser for GitLab dates.
    ///
    /// How GitLab provides dates according to their docs:
    /// ```
    /// Date time string, ISO 8601 formatted.
    /// Example: 2016-03-11T03:45:40Z (requires administrator or project/group owner rights)
    /// ```
    private static let dateParser: DateFormatter = .fullISO8601

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateParser)
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    public init() {}

    public func deseriaize<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        try Self.decoder.decode(type, from: data)
    }
}
