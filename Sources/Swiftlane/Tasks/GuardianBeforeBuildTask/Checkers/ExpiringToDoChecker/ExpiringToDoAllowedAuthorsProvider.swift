//

import Foundation
import SwiftlaneCore
import GitLabAPI
import Guardian

public protocol ExpiringToDoAllowedAuthorsProviding {
    func allowedToDoAuthors() throws -> [String]
}

public class GitLabExpiringToDoAllowedAuthorsProvider: ExpiringToDoAllowedAuthorsProviding {
    private let logger: Logging
    private let gitlabApi: GitLabAPIClientProtocol
    
    public let gitlabGroupIDToFetchMembers: Int
    
    /// - Parameters:
    ///   - gitlabGroupIDToFetchMembers: members of the groups will be treated as possible authors of a TODO.
    public init(
        logger: Logging,
        gitlabApi: GitLabAPIClientProtocol,
        gitlabGroupIDToFetchMembers: Int
    ) {
        self.logger = logger
        self.gitlabApi = gitlabApi
        self.gitlabGroupIDToFetchMembers = gitlabGroupIDToFetchMembers
    }
    
    private func groupMembers() throws -> [Member] {
        
        try gitlabApi.groupMembers(
            group: GitLab.Group(id: gitlabGroupIDToFetchMembers)
        ).await()
    }

    public func allowedToDoAuthors() throws -> [String] {
        let gitlabMembers = try groupMembers()
            .filter { !$0.username.contains("r2d2") }
            .map(\.username)

        logger.debug("GitLab group has \(gitlabMembers.count) members: \(gitlabMembers)")
        return gitlabMembers
    }
}
