//

import Foundation

public struct MergeRequestApprovalRule: Decodable {
    public let id: Int
    public let name: String
    public let ruleType: String
    public let eligibleApprovers: [Member]?
    public let approvalsRequired: Int?
}
