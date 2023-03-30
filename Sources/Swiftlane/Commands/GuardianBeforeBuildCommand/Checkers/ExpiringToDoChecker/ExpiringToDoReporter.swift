//

import Foundation
import Guardian
import SwiftlaneCore

// sourcery: AutoMockable
public protocol ExpiringToDoReporting {
    func report(todos: [VerifiedExpiringTodoModel])
    func reportExpiredToDoCheckerDisabled()
    func reportCheckIsDisabledForSourceBranch(sourceBranch: String)
    func reportCheckIsDisabledForTargetBranch(targetBranch: String)
    func reportSuccessIfNeeded()
}

public final class ExpiringToDoReporter {
    private let reporter: MergeRequestReporting
    private let todosSorter: ExpiringToDoSorting

    private let failIfExpiredDetected: Bool
    /// Don't fail if expired todos or invalid date format detected.
    private let needFail: Bool

    public init(
        reporter: MergeRequestReporting,
        todosSorter: ExpiringToDoSorting,
        failIfExpiredDetected: Bool,
        needFail: Bool
    ) {
        self.reporter = reporter
        self.todosSorter = todosSorter
        self.failIfExpiredDetected = failIfExpiredDetected
        self.needFail = needFail
    }

    private func reportFail(_ message: String, preventFail: Bool) {
        if !preventFail {
            reporter.fail(message)
        } else {
            reporter.warn(message)
        }
    }

    // swiftformat:disable indent
	private func report(todo verified: VerifiedExpiringTodoModel) {
		let preventFail = !needFail
		let todo = verified.parsed

		var todoTextAndFileLine = "\n\n**\(todo.fullMatch)**.\n\n" + "_\(todo.file):\(todo.line)_"
		let noAuthorMessage =
			"_TODO_ has no author. Format: `// TODO: [date] @gitlab.username Refactor this.` \n\n" +
			"Outdated _TODO_ witout author is blocking everyone!"

		if todo.author == nil {
			reporter.message(
				noAuthorMessage + " " + todoTextAndFileLine
			)
			todoTextAndFileLine += "\n\n" + noAuthorMessage
		}

		// Preventing GitLab mention.
		let suppressedAuthorMentionToDoTextAndFileLine = todoTextAndFileLine.replacingOccurrences(of: " @", with: " ")

		switch verified.status {
		case .valid:
			break

		case let .approachingExpiryDate(daysLeft):
			reporter.warn(
				"You have \(daysLeft) days before \(todo.dateString), to fix _TODO_:" + suppressedAuthorMentionToDoTextAndFileLine
			)

		case let .expiredError(daysAgo):
			reportFail(
			    "\(daysAgo) days ago (\(todo.dateString)) outdated _TODO_:" + todoTextAndFileLine,
			    preventFail: preventFail || !failIfExpiredDetected
			)

		case let .expiredWarning(daysAgo):
			reporter.warn(
				"\(daysAgo) days ago (\(todo.dateString)) outdated _TODO_:" + suppressedAuthorMentionToDoTextAndFileLine
			)

		case let .invalidDateFormat(expectedFormat):
			reportFail(
			    "Wronge date in _TODO_.\n\n" +
				"Need formate date: `\(expectedFormat)`.\n\n" + todoTextAndFileLine,
			    preventFail: preventFail
			)

		case let .tooFarInFuture(maxFutureDays):
			reportFail(
			    "Is date _TODO_ too far in future.\n\n" +
				"Max days allowed for _TODO_: `\(maxFutureDays)`.\n\n" + todoTextAndFileLine,
			    preventFail: preventFail
			)

		case let .authorIsNotInAllowedGitLabGroup(author, members):
			reportFail(
			    "User `\(author.quoted)` is not in allowed authors GitLab Group.\n\n" +
				"Allowed authors: \(members.map { "`\($0)`" }.joined(separator: ", ")).\n\n" + suppressedAuthorMentionToDoTextAndFileLine,
			    preventFail: preventFail
			)

		case let .authorIsNotListedInTeamsConfigs(author):
			reportFail(
			    "User `\(author.quoted)` not found in _TODO_ configs.\n\n" + todoTextAndFileLine,
			    preventFail: preventFail
			)

		case .emptyAuthorIsNotAllowed:
			reportFail(
			    "_TODO_ without author is not allowed.\n\n" + todoTextAndFileLine,
			    preventFail: preventFail
			)
		}
	}
	// swiftformat:enable indent
}

extension ExpiringToDoReporter: ExpiringToDoReporting {
    public func report(todos: [VerifiedExpiringTodoModel]) {
        todosSorter.sort(todos: todos).forEach {
            report(todo: $0)
        }
    }

    public func reportExpiredToDoCheckerDisabled() {
        reporter.message("_TODO_ date check is disabled.")
    }

    public func reportCheckIsDisabledForSourceBranch(sourceBranch: String) {
        reporter.message("_TODO_ check is disabled for source branch `\(sourceBranch)`.")
    }

    public func reportCheckIsDisabledForTargetBranch(targetBranch: String) {
        reporter.message("_TODO_ check is disabled for target branch `\(targetBranch)`.")
    }

    public func reportSuccessIfNeeded() {
        guard !reporter.hasFails() else {
            return
        }
        reporter.success("_TODO_ dates are ok")
    }
}
