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
    private let reporter: MergeRequestReporter

    public init(
        reporter: MergeRequestReporter
    ) {
        self.reporter = reporter
    }
}

// swiftformat:disable indent
extension MergeRequestAuthorCheckerReporter: MergeRequestAuthorCheckerReporting {
	public func reportAvatarIsNotSet(profileSettingsURL: String) {
		reporter.fail(
			"Profile photo is not installed! " +
			"Please [set](\(profileSettingsURL))!"
		)
	}

	public func reportInvalidAuthorNameOnGitLab(profileSettingsURL: String, description: String) {
		reporter.fail(
			"Error in GitLab profile name. \(description)\n\n [Change name here](\(profileSettingsURL))"
		)
	}

	public func reportInvalidAuthorNameInCommit(commitSHA: String, description: String) {
		reporter.fail(
			"Error in the name of the commit author \(commitSHA). \(description)"
		)
	}

	public func reportSuccessIfNeeded() {
		if !reporter.hasFails() {
			reporter.success("The avatar and name on GitLab, as well as the author's name in the comments are checked.")
		}
	}
}

// swiftformat:enable indent
