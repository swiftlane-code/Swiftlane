//

import Foundation

public struct DetailVersion: Codable {
    public let linkString: String
    public let id: String
    public let name: String
    //	public let issusesStatus: IssuesStatus // In API V2 not found

    enum CodingKeys: String, CodingKey {
        case name, id
        case linkString = "self"
        //		case issusesStatus = "issuesStatusForFixVersion"
    }
}
