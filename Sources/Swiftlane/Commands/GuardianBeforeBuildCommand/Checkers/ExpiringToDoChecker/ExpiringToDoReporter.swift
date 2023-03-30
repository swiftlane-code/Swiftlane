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
			"У _TODO_ нет автора. Формат установки автора: `// TODO: [date] @gitlab.username Refactor this.` \n\n" +
			"Просроченное _TODO_ без автора блокирует всех!"

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
				"Осталось \(daysLeft) дней до \(todo.dateString), чтобы исправить _TODO_:" + suppressedAuthorMentionToDoTextAndFileLine
			)

		case let .expiredError(daysAgo):
			reportFail(
			    "\(daysAgo) дней назад (\(todo.dateString)) просрочена _TODO_:" + todoTextAndFileLine,
			    preventFail: preventFail || !failIfExpiredDetected
			)

		case let .expiredWarning(daysAgo):
			reporter.warn(
				"\(daysAgo) дней назад (\(todo.dateString)) просрочена _TODO_:" + suppressedAuthorMentionToDoTextAndFileLine
			)

		case let .invalidDateFormat(expectedFormat):
			reportFail(
			    "У вас ошибочка в дате _TODO_.\n\n" +
				"Ожидаемый формат даты: `\(expectedFormat)`.\n\n" + todoTextAndFileLine,
			    preventFail: preventFail
			)

		case let .tooFarInFuture(maxFutureDays):
			reportFail(
			    "Дата _TODO_ слишком далеко в будущем.\n\n" +
				"Максимум дней разрешено до даты _TODO_: `\(maxFutureDays)`.\n\n" + todoTextAndFileLine,
			    preventFail: preventFail
			)

		case let .authorIsNotInAllowedGitLabGroup(author, members):
			reportFail(
			    "Пользователь `\(author.quoted)` не может быть назначен автором _TODO_ так как не является мембером группы GitLab.\n\n" +
				"Возможные авторы: \(members.map { "`\($0)`" }.joined(separator: ", ")).\n\n" + suppressedAuthorMentionToDoTextAndFileLine,
			    preventFail: preventFail
			)

		case let .authorIsNotListedInTeamsConfigs(author):
			reportFail(
			    "Пользователя `\(author.quoted)` нет в конфигах команд-авторов _TODO_.\n\n" + todoTextAndFileLine,
			    preventFail: preventFail
			)

		case .emptyAuthorIsNotAllowed:
			reportFail(
			    "_TODO_ без указания автора запрещены.\n\n" + todoTextAndFileLine,
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
        reporter.message("Проверка дат _TODO_-шек отключена.")
    }

    public func reportCheckIsDisabledForSourceBranch(sourceBranch: String) {
        reporter.message("_TODO_ не проверяются для MR-ов из ветки `\(sourceBranch)`.")
    }

    public func reportCheckIsDisabledForTargetBranch(targetBranch: String) {
        reporter.message("_TODO_ не проверяются для MR-ов в ветку `\(targetBranch)`.")
    }

    public func reportSuccessIfNeeded() {
        guard !reporter.hasFails() else {
            return
        }
        reporter.success("Даты _TODO_-шек проверены")
    }
}
