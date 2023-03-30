//

import Foundation
import SwiftlaneCore

public struct ParsedExpiringToDoModel: Equatable, Encodable {
    public let file: RelativePath
    public let line: UInt
    public let fullMatch: String
    public let author: String?
    public let dateString: String
}

public struct VerifiedExpiringTodoModel: Equatable, Encodable {
    public let parsed: ParsedExpiringToDoModel
    public let status: ExpiringToDoStatus
}

public enum ExpiringToDoStatus: Equatable, Encodable {
    case valid
    case approachingExpiryDate(daysLeft: UInt)
    case expiredError(daysAgo: UInt)
    case expiredWarning(daysAgo: UInt)
    case invalidDateFormat(expectedFormat: String)
    case tooFarInFuture(maxFutureDays: Int)
    case authorIsNotInAllowedGitLabGroup(author: String, members: [String])
    case authorIsNotListedInTeamsConfigs(author: String)
    case emptyAuthorIsNotAllowed
}

public protocol ExpiringToDoVerifiing {
    func verify(
        todo: ParsedExpiringToDoModel,
        maxFutureDays: Int?,
        allowedAuthors: [String],
        userToBeBlocked: String
    ) throws -> VerifiedExpiringTodoModel
}

/// Verifies expring todo's dates in code.
public class ExpiringToDoVerifier {
    private let warningAfterDaysLeft: UInt
    private let dateParser = DateFormatter()
    private let responsibilityProvider: ExpiringToDoResponsibilityProviding

    /// - Parameter dateFormat: e.g. `"dd.MM.yy"`.
    /// - Parameter warningAfterDaysLeft: max number of days until expiry date to report warning.
    public init(dateFormat: String, warningAfterDaysLeft: UInt, responsibilityProvider: ExpiringToDoResponsibilityProviding) {
        self.warningAfterDaysLeft = warningAfterDaysLeft
        dateParser.dateFormat = dateFormat
        self.responsibilityProvider = responsibilityProvider
    }

    private func toDoStatus(
        parsedToDo todo: ParsedExpiringToDoModel,
        warningDaysBeforeExpiry: UInt,
        maxFutureDays: Int?,
        allowedAuthors: [String],
        userToBeBlocked: String,
        now: Date = Date()
    ) -> ExpiringToDoStatus {
        guard let date = dateParser.date(from: todo.dateString) else {
            return .invalidDateFormat(expectedFormat: dateParser.dateFormat)
        }

        if let author = todo.author {
            guard allowedAuthors.contains(author) else {
                return .authorIsNotInAllowedGitLabGroup(author: author, members: allowedAuthors)
            }

            guard responsibilityProvider.isAuthorAllowed(username: author) else {
                return .authorIsNotListedInTeamsConfigs(author: author)
            }
        } else {
            guard responsibilityProvider.isNilAuthorAllowed() else {
                return .emptyAuthorIsNotAllowed
            }
        }

        /// daysLeft is:
        /// * `> 0`  before the date;
        /// * `== 0` at the day before the date;
        /// * `== 0` at the day of the date;
        /// * `< 0`  after the day of the date.
        let daysLeft = date.daysSince(start: now)
        let absDaysLeft = UInt(abs(daysLeft)) + 1

        if now >= date {
            // Check if expired TODO should NOT block current merge request author
            let error = responsibilityProvider.shouldToDoBlock(
                username: userToBeBlocked,
                todoAuthor: todo.author
            )
            return error ? .expiredError(daysAgo: absDaysLeft) : .expiredWarning(daysAgo: absDaysLeft)
        }

        if daysLeft <= warningDaysBeforeExpiry {
            return .approachingExpiryDate(daysLeft: absDaysLeft)
        }

        if let maxFutureDays = maxFutureDays, daysLeft > maxFutureDays {
            return .tooFarInFuture(maxFutureDays: maxFutureDays)
        }

        return .valid
    }

    public func verify(
        todo: ParsedExpiringToDoModel,
        maxFutureDays: Int?,
        allowedAuthors: [String],
        userToBeBlocked: String,
        now: Date
    ) throws -> VerifiedExpiringTodoModel {
        let status = toDoStatus(
            parsedToDo: todo,
            warningDaysBeforeExpiry: warningAfterDaysLeft,
            maxFutureDays: maxFutureDays,
            allowedAuthors: allowedAuthors,
            userToBeBlocked: userToBeBlocked,
            now: now
        )

        return VerifiedExpiringTodoModel(
            parsed: todo,
            status: status
        )
    }
}

extension ExpiringToDoVerifier: ExpiringToDoVerifiing {
    public func verify(
        todo: ParsedExpiringToDoModel,
        maxFutureDays: Int?,
        allowedAuthors: [String],
        userToBeBlocked: String
    ) throws -> VerifiedExpiringTodoModel {
        try verify(
            todo: todo,
            maxFutureDays: maxFutureDays,
            allowedAuthors: allowedAuthors,
            userToBeBlocked: userToBeBlocked,
            now: Date()
        )
    }
}
