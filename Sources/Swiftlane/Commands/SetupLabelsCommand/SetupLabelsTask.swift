
import Foundation
import GitLabAPI
import Guardian
import Networking
import SwiftlaneCore

public extension SetupLabelsTask {
    struct LabelsConfig: Decodable {
        public let byBranches: [String: [StringMatcher]]
        public let byChangedFiles: [String: [StringMatcher]]

        public enum CodingKeys: String, CodingKey {
            case byBranches = "by_branches"
            case byChangedFiles = "by_changed_files"
        }
    }
}

public extension SetupLabelsTask {
    struct Config {
        public let labelsConfig: LabelsConfig
    }
}

public final class SetupLabelsTask {
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

    private var knownLabels: [String] {
        Array(config.labelsConfig.byBranches.keys) + Array(config.labelsConfig.byChangedFiles.keys)
    }

    private func currentMergeRequest() throws -> MergeRequest {
        try gitlabApi.mergeRequest(
            projectId: try gitlabCIEnvironment.int(.CI_PROJECT_ID),
            mergeRequestIid: try gitlabCIEnvironment.int(.CI_MERGE_REQUEST_IID),
            loadChanges: false
        ).await()
    }

    private func getDiff() throws -> RepositoryCompareResult {
        try gitlabApi.repositoryDiff(
            projectId: try gitlabCIEnvironment.int(.CI_PROJECT_ID),
            source: try gitlabCIEnvironment.string(.CI_MERGE_REQUEST_SOURCE_BRANCH_NAME),
            target: try gitlabCIEnvironment.string(.CI_MERGE_REQUEST_TARGET_BRANCH_NAME)
        ).await()
    }

    @discardableResult
    private func setLabelsInMergeRequest(addLabels: [String], removeLabels: [String]) throws -> MergeRequest {
        try gitlabApi.setMergeRequest(
            projectId: try gitlabCIEnvironment.int(.CI_PROJECT_ID),
            mergeRequestIid: try gitlabCIEnvironment.int(.CI_MERGE_REQUEST_IID),
            addLabels: addLabels,
            removeLabels: removeLabels
        ).await()
    }

    private func labelsByBranches() throws -> [String] {
        let targetBranch = try gitlabCIEnvironment.string(.CI_MERGE_REQUEST_TARGET_BRANCH_NAME)

        return config.labelsConfig.byBranches
            .filter { $0.value.isMatching(string: targetBranch) }
            .map(\.key)
    }

    private func labelsByChangedFiles(_ changedFiles: [String]) throws -> [String] {
        config.labelsConfig.byChangedFiles
            .filter { labelConfig in
                guard labelConfig.value.first(where: { labelRegex in
                    changedFiles.contains(where: { labelRegex.isMatching($0) })
                }) != nil else {
                    return false
                }
                return true
            }
            .map(\.key)
    }

    public func run() throws {
        var labels = try labelsByBranches()

        let changes = try getDiff().diffs.map(\.newPath)
        let mergeRequest = try currentMergeRequest()

        labels.append(contentsOf: try labelsByChangedFiles(changes))

        let currentLabels = Set(mergeRequest.labels)
        let targetLabels = Set(labels)
        let addLabels = targetLabels.subtracting(currentLabels).asArray
        let removeLabels = currentLabels.subtracting(targetLabels).intersection(Set(knownLabels)).asArray

        try setLabelsInMergeRequest(addLabels: addLabels, removeLabels: removeLabels)
    }
}
