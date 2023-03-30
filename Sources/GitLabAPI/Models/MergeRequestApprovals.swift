//

import Foundation

public struct MergeRequestApprovals: Decodable {
    public let approvalRulesLeft: [MergeRequestApprovalRule]
    public let approvedBy: [ApprovedByContainer]
    public let approvalsLeft: Int

    public struct ApprovedByContainer: Decodable {
        public let user: Member?
    }
}
