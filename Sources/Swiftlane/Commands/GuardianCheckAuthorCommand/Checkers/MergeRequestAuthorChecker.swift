//

import Foundation
import GitLabAPI
import Guardian
import SwiftlaneCore

public protocol MergeRequestAuthorChecking {
    func check() throws
}

public class MergeRequestAuthorChecker {
    private let reporter: MergeRequestAuthorCheckerReporting
    private let gitlabApi: GitLabAPIClientProtocol
    private let gitlabCIEnvironment: GitLabCIEnvironmentReading

    private let validGitLabUserName: DescriptiveStringMatcher
    private let validCommitAuthorName: DescriptiveStringMatcher

    public init(
        reporter: MergeRequestAuthorCheckerReporting,
        gitlabApi: GitLabAPIClientProtocol,
        gitlabCIEnvironment: GitLabCIEnvironmentReading,
        validGitLabUserName: DescriptiveStringMatcher,
        validCommitAuthorName: DescriptiveStringMatcher
    ) {
        self.reporter = reporter
        self.gitlabApi = gitlabApi
        self.gitlabCIEnvironment = gitlabCIEnvironment
        self.validGitLabUserName = validGitLabUserName
        self.validCommitAuthorName = validCommitAuthorName
    }

    private func makeProfileSettingsURL() throws -> String {
        let projectURLString = try gitlabCIEnvironment.string(.CI_PROJECT_URL)
        var projectURL = try URLComponents(string: projectURLString).unwrap(
            errorDescription: "Unable to parse CI_PROJECT_URL"
        )

        projectURL.path = "/-/profile"

        return try projectURL.string.unwrap(
            errorDescription: "Unable to make profile settings url"
        )
    }

    private func checkThatAuthorHasAvatar(author: Member, profileSettingsURL: String) throws {
        /// Custom avatar always contains userID in its url.
        /// Custom avatar: https://domain.gitlab.com/uploads/-/system/user/avatar/631/avatar.png
        /// Default avatar: https://secure.gravatar.com/avatar/c9f684faa2f288881793f1a77879d420?s=80&d=identicon
        let avatarURL = author.avatarUrl ?? ""

        if !avatarURL.contains("user/avatar/\(author.id)/") {
            reporter.reportAvatarIsNotSet(profileSettingsURL: profileSettingsURL)
        }
    }

    private func checkThatAuthorNameIsValid(author: Member, profileSettingsURL: String) throws {
        guard validGitLabUserName.matcher.isMatching(author.name) else {
            reporter.reportInvalidAuthorNameOnGitLab(
                profileSettingsURL: profileSettingsURL,
                description: validGitLabUserName.description
            )
            return
        }
        // Name on GitLab is good
    }

    private func checkThatCommitsAuthorIsCorrect() throws {
        // Name in commits

        let commits = try gitlabApi.mergeRequestCommits(
            projectId: try gitlabCIEnvironment.int(.CI_PROJECT_ID),
            mergeRequestIid: try gitlabCIEnvironment.int(.CI_MERGE_REQUEST_IID)
        ).await()

        commits.forEach {
            print("Checking commit \($0.asPrettyJSON())")
            if !validCommitAuthorName.matcher.isMatching($0.authorName) {
                reporter.reportInvalidAuthorNameInCommit(
                    commitSHA: $0.shortSHA,
                    description: validCommitAuthorName.description
                )
            }
        }
    }
}

extension MergeRequestAuthorChecker: MergeRequestAuthorChecking {
    public func check() throws {
        let mergeRequest = try gitlabApi.mergeRequest(
            projectId: try gitlabCIEnvironment.int(.CI_PROJECT_ID),
            mergeRequestIid: try gitlabCIEnvironment.int(.CI_MERGE_REQUEST_IID),
            loadChanges: false
        ).await()

        let author = try mergeRequest.author
            .unwrap(errorDescription: "Unable to get Merge Request author")

        let profileSettingsURL = try makeProfileSettingsURL()

        try checkThatAuthorHasAvatar(author: author, profileSettingsURL: profileSettingsURL)
        try checkThatAuthorNameIsValid(author: author, profileSettingsURL: profileSettingsURL)
        try checkThatCommitsAuthorIsCorrect()

        reporter.reportSuccessIfNeeded()
    }
}
