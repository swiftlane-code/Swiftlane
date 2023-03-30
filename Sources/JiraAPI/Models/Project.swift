//

import Foundation

/// Jira project info.
///
/// Note: This model does not parse all the data return by the API.
public struct Project: Codable {
    public let id: String
    public let name: String
    public let versions: [FullVersion]
}
