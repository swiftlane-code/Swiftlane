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
			"Профиля фотография не установлена у вас, вижу я! " +
			"Пожалуйста, железку уважьте, [установите](\(profileSettingsURL))!"
		)
	}

	public func reportInvalidAuthorNameOnGitLab(profileSettingsURL: String, description: String) {
		reporter.fail(
			"Ошибка в имени профиля GitLab. \(description)\n\n [Изменить имя можно тут](\(profileSettingsURL))"
		)
	}

	public func reportInvalidAuthorNameInCommit(commitSHA: String, description: String) {
		reporter.fail(
			"Ошибка в имени автора коммита \(commitSHA). \(description)"
		)
	}

	public func reportSuccessIfNeeded() {
		if !reporter.hasFails() {
			reporter.success("Аватар и имя на GitLab, а также имя автора в коммитах проверены.")
		}
	}
}

// swiftformat:enable indent
