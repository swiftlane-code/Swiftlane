
import Foundation
import GitLabAPI
import Guardian
import Networking
import SwiftlaneCore

public extension SetupReviewersTask {
    struct ReviewersConfig: Decodable {
        public struct Reviewers: Decodable {
            public let defaults: [String]
            public let groups: [String: [String]]
            public let perAuthor: [String: [String]]
        }

        public let reviewers: Reviewers
    }
}

public extension SetupReviewersTask {
    struct Config {
        public let reviewersConfig: ReviewersConfig
        public let gitlabGroupID: Int
    }
}

public extension SetupReviewersTask {
    enum Errors: Error {
        case notFoundAuthor
    }
}

public final class SetupReviewersTask {
    private let logger: Logging
    private let config: Config
    private let gitlabCIEnvironment: GitLabCIEnvironmentReading
    private let gitlabApi: GitLabAPIClientProtocol

    private var reviewersFromConfig: ReviewersConfig.Reviewers { config.reviewersConfig.reviewers }

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

    private func gitlabMembers() throws -> [Member] {
        try gitlabApi.groupMembers(
            group: .init(id: config.gitlabGroupID)
        ).await()
    }

    @discardableResult
    private func setReviewersInMergeRequest(_ reviewersIds: [Int]) throws -> MergeRequest {
        try gitlabApi.setMergeRequest(
            projectId: try gitlabCIEnvironment.int(.CI_PROJECT_ID),
            mergeRequestIid: try gitlabCIEnvironment.int(.CI_MERGE_REQUEST_IID),
            reviewersIds: reviewersIds
        ).await()
    }

    private func reviewersUsernames(for author: String) -> [String] {
        let reviewers = reviewersFromConfig.perAuthor[author] ?? reviewersFromConfig.defaults

        return reviewers
            .flatMap { reviewersFromConfig.groups[$0] ?? [$0] }
            .removingDuplicates
    }

    public func run() throws {
        let mergeRequest = try currentMergeRequest()
        guard let authorUsername = mergeRequest.author?.username else {
            throw Errors.notFoundAuthor
        }

        let reviewersForAuthor = reviewersUsernames(for: authorUsername)

        logger.info("Found reviewers for current request: \"\(reviewersForAuthor)\"")

        let gitlabMembers = try gitlabMembers()

        let reviewersIds = reviewersForAuthor.compactMap { reviewer in
            gitlabMembers.first(where: { $0.username == reviewer })?.id
        }

        logger.debug("reviewers_ids to set: \"\(reviewersIds)\"")

        try setReviewersInMergeRequest(reviewersIds)
    }
}
