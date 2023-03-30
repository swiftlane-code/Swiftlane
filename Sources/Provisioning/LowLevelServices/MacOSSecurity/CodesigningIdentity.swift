//

import Foundation

public struct CodesigningIdentity: Codable {
    public let fingerprint: String
    public let type: String
    public let name: String
    public let teamID: String
}
