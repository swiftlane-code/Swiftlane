
import Foundation
import GitLabAPI
import Guardian
import Networking
import SwiftlaneCore

public extension SetupAssigneeTask {
    struct Config {}
}

public extension SetupAssigneeTask {
    enum Errors: Error {
        case notFoundAuthor
    }
}

public final class SetupAssigneeTask {
    private let logger: Logging
    private let config: Config
    private let gitlabCIEnvironment: GitLabCIEnvironmentReading
    private let gitlabApi: GitLabAPIClientProtocol

    public init(
        logger: Logging,
        config: Config,
        gitlabCIEnvironment: GitLabCIEnvironmentReading,
        gitlabApi: GitLabAPIClientProtocol
    ) {
        self.logger = logger
        self.config = config
        self.gitlabCIEnvironment = gitlabCIEnvironment
        self.gitlabApi = gitlabApi
    }

    private func currentMergeRequest() throws -> MergeRequest {
        try gitlabApi.mergeRequest(
            projectId: try gitlabCIEnvironment.int(.CI_PROJECT_ID),
            mergeRequestIid: try gitlabCIEnvironment.int(.CI_MERGE_REQUEST_IID),
            loadChanges: false
        ).await()
    }

    @discardableResult
    private func setAssigneeInMergeRequest(_ assigneeId: Int) throws -> MergeRequest {
        try gitlabApi.setMergeRequest(
            projectId: try gitlabCIEnvironment.int(.CI_PROJECT_ID),
            mergeRequestIid: try gitlabCIEnvironment.int(.CI_MERGE_REQUEST_IID),
            assigneeId: assigneeId
        ).await()
    }

    public func run() throws {
        let mergeRequest = try currentMergeRequest()
        guard let author = mergeRequest.author else {
            throw Errors.notFoundAuthor
        }

        logger.important("Author of the request: \"\(author.username)\"")

        try setAssigneeInMergeRequest(author.id)
    }
}
