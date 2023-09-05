//

import Foundation
import Guardian

// sourcery: AutoMockable
public protocol MergeRequestAuthorCheckerReporting {
    func reportAvatarIsNotSet(profileSettingsURL: String)
    func reportInvalidAuthorNameOnGitLab(profileSettingsURL: String, description: String)
    func reportInvalidAuthorNameInCommit(commitSHA: String, description: String)
    func reportSuccessIfNeeded()
}

public class MergeRequestAuthorCheckerReporter {
    private let reporter: GitLabMergeRequestReporter

    public init(
        reporter: GitLabMergeRequestReporter
    ) {
        self.reporter = reporter
    }
}

// swiftformat:disable indent
extension MergeRequestAuthorCheckerReporter: MergeRequestAuthorCheckerReporting {
	public func reportAvatarIsNotSet(profileSettingsURL: String) {
		reporter.fail(
			"Please set your profile's avatar [here](\(profileSettingsURL))!"
		)
	}

	public func reportInvalidAuthorNameOnGitLab(profileSettingsURL: String, description: String) {
		reporter.fail(
			"Your GitLab profile's name doesn't match our convention. \(description)\n\n [Please change it here](\(profileSettingsURL))"
		)
	}

	public func reportInvalidAuthorNameInCommit(commitSHA: String, description: String) {
		reporter.fail(
			"Detected strange commit author name in commit \(commitSHA). \(description)"
		)
	}

	public func reportSuccessIfNeeded() {
		if !reporter.hasFails() {
			reporter.success("GitLab profile name, avatar, and commits' author name are ok.")
		}
	}
}

// swiftformat:enable indent
