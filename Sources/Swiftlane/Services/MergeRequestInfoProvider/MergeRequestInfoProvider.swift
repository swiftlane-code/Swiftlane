//

import Foundation
import SwiftlaneCore
import GitLabAPI
import Guardian

public protocol MergeRequestInfoProviding {
    func author() throws -> MergeRequestInfo.Author
    func sourceBranch() throws -> String
    func targetBranch() throws -> String
}

public class GitLabMergeRequestInfoProvider: MergeRequestInfoProviding {
    private let gitlabCIEnvironmentReader: GitLabCIEnvironmentReading
    private let gitlabApi: GitLabAPIClientProtocol
    
    public init(
        gitlabCIEnvironmentReader: GitLabCIEnvironmentReading,
        gitlabApi: GitLabAPIClientProtocol
    ) {
        self.gitlabCIEnvironmentReader = gitlabCIEnvironmentReader
        self.gitlabApi = gitlabApi
    }
    
    public func author() throws -> MergeRequestInfo.Author {
        let mergeRequest = try gitlabApi.mergeRequest(
            projectId: try gitlabCIEnvironmentReader.int(.CI_PROJECT_ID),
            mergeRequestIid: try gitlabCIEnvironmentReader.int(.CI_MERGE_REQUEST_IID),
            loadChanges: false
        ).await()

        let author = try mergeRequest.author
            .unwrap(errorDescription: "Unable to get Merge Request author")

        return MergeRequestInfo.Author(
            id: author.id,
            name: author.name,
            username: author.username,
            avatarUrl: author.avatarUrl,
            webUrl: author.webUrl
        )
    }
    
    public func sourceBranch() throws -> String {
        try gitlabCIEnvironmentReader.string(.CI_MERGE_REQUEST_SOURCE_BRANCH_NAME)
    }
    
    public func targetBranch() throws -> String {
        try gitlabCIEnvironmentReader.string(.CI_MERGE_REQUEST_TARGET_BRANCH_NAME)
    }
}
