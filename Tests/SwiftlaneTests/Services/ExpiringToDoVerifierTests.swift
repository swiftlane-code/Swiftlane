//

import Foundation
import SwiftlaneCore
import SwiftlaneUnitTestTools
import XCTest

@testable import Swiftlane

class ExpiringToDoVerifierTests: XCTestCase {
    var verifier: ExpiringToDoVerifier!
    var responsibilityProvider: ExpiringToDoResponsibilityProvidingMock!

    override func setUp() {
        super.setUp()

        responsibilityProvider = ExpiringToDoResponsibilityProvidingMock()

        verifier = ExpiringToDoVerifier(
            dateFormat: "dd.MM.yy",
            warningAfterDaysLeft: 111,
            responsibilityProvider: responsibilityProvider
        )
    }

    override func tearDown() {
        verifier = nil
        responsibilityProvider = nil

        super.tearDown()
    }

    private func check(
        _ model: VerifiedExpiringTodoModel,
        expectedStatus: ExpiringToDoStatus,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(model.status, expectedStatus, file: file, line: line)
    }

    func test_oneDayDistanceTodosAreCalculatedCorrectly() throws {
        // given
        let now = try Date.from(string: "25.05.3022 11:59", format: "dd.MM.yy HH:mm")

        responsibilityProvider.given(.shouldToDoBlock(
            username: .any,
            todoAuthor: .any,
            willReturn: true
        ))

        responsibilityProvider.given(.isNilAuthorAllowed(
            willReturn: true
        ))

        // when & then
        check(
            try verifier.verify(
                todo: ParsedExpiringToDoModel(
                    file: .random(),
                    line: 1,
                    fullMatch: "",
                    author: nil,
                    dateString: "26/05/3022"
                ),
                maxFutureDays: 365,
                allowedAuthors: [],
                userToBeBlocked: "",
                now: now
            ),
            expectedStatus: .approachingExpiryDate(daysLeft: 1)
        )

        check(
            try verifier.verify(
                todo: ParsedExpiringToDoModel(
                    file: .random(),
                    line: 2,
                    fullMatch: "",
                    author: nil,
                    dateString: "25/05/3022"
                ),
                maxFutureDays: 365,
                allowedAuthors: [],
                userToBeBlocked: "",
                now: now
            ),
            expectedStatus: .expiredError(daysAgo: 1)
        )

        check(
            try verifier.verify(
                todo: ParsedExpiringToDoModel(
                    file: .random(),
                    line: 3,
                    fullMatch: "",
                    author: nil,
                    dateString: "24/05/3022"
                ),
                maxFutureDays: 365,
                allowedAuthors: [],
                userToBeBlocked: "",
                now: now
            ),
            expectedStatus: .expiredError(daysAgo: 2)
        )
    }

    func test_todosAreVerifiedCorrectly() throws {
        let now = try Date.from(string: "25.05.3022 15:59", format: "dd.MM.yy HH:mm")

        responsibilityProvider.given(.shouldToDoBlock(
            username: .any,
            todoAuthor: .any,
            willReturn: true
        ))

        responsibilityProvider.given(.isNilAuthorAllowed(
            willReturn: true
        ))

        check(
            try verifier.verify(
                todo: ParsedExpiringToDoModel(
                    file: .random(),
                    line: 1,
                    fullMatch: "",
                    author: nil,
                    dateString: "03/15/3022"
                ),
                maxFutureDays: 365,
                allowedAuthors: [],
                userToBeBlocked: "",
                now: now
            ),
            expectedStatus: .invalidDateFormat(expectedFormat: "dd.MM.yy")
        )

        check(
            try verifier.verify(
                todo: ParsedExpiringToDoModel(
                    file: .random(),
                    line: 2,
                    fullMatch: "",
                    author: nil,
                    dateString: "01.01.10"
                ),
                maxFutureDays: 365,
                allowedAuthors: [],
                userToBeBlocked: "",
                now: now
            ),
            expectedStatus: .expiredError(daysAgo: 369_770)
        )

        check(
            try verifier.verify(
                todo: ParsedExpiringToDoModel(
                    file: .random(),
                    line: 1,
                    fullMatch: "",
                    author: nil,
                    dateString: "30/05/3022"
                ),
                maxFutureDays: 365,
                allowedAuthors: [],
                userToBeBlocked: "",
                now: now
            ),
            expectedStatus: .approachingExpiryDate(daysLeft: 5)
        )

        check(
            try verifier.verify(
                todo: ParsedExpiringToDoModel(
                    file: .random(),
                    line: 1,
                    fullMatch: "",
                    author: nil,
                    dateString: "30/05/3023"
                ),
                maxFutureDays: 365,
                allowedAuthors: [],
                userToBeBlocked: "",
                now: now
            ),
            expectedStatus: .tooFarInFuture(maxFutureDays: 365)
        )

        check(
            try verifier.verify(
                todo: ParsedExpiringToDoModel(
                    file: .random(),
                    line: 1,
                    fullMatch: "",
                    author: nil,
                    dateString: "02/02/3022"
                ),
                maxFutureDays: 365,
                allowedAuthors: [],
                userToBeBlocked: "",
                now: now
            ),
            expectedStatus: .expiredError(daysAgo: 113)
        )

        check(
            try verifier.verify(
                todo: ParsedExpiringToDoModel(
                    file: .random(),
                    line: 4,
                    fullMatch: "",
                    author: nil,
                    dateString: "1.1.10"
                ),
                maxFutureDays: 365,
                allowedAuthors: [],
                userToBeBlocked: "",
                now: now
            ),
            expectedStatus: .expiredError(daysAgo: 369_770)
        )

        responsibilityProvider.given(.isAuthorAllowed(username: .value("user.name"), willReturn: true))
        check(
            try verifier.verify(
                todo: ParsedExpiringToDoModel(
                    file: .random(),
                    line: 1,
                    fullMatch: "",
                    author: "user.name",
                    dateString: "30/12/3022"
                ),
                maxFutureDays: 365,
                allowedAuthors: ["ADMIN"],
                userToBeBlocked: "",
                now: now
            ),
            expectedStatus: .authorIsNotInAllowedGitLabGroup(author: "user.name", members: ["ADMIN"])
        )

        responsibilityProvider.given(.isAuthorAllowed(username: .value("disallowed.author"), willReturn: false))
        check(
            try verifier.verify(
                todo: ParsedExpiringToDoModel(
                    file: .random(),
                    line: 1,
                    fullMatch: "",
                    author: "disallowed.author",
                    dateString: "30/12/3022"
                ),
                maxFutureDays: 365,
                allowedAuthors: ["disallowed.author"],
                userToBeBlocked: "",
                now: now
            ),
            expectedStatus: .authorIsNotListedInTeamsConfigs(author: "disallowed.author")
        )

        check(
            try verifier.verify(
                todo: ParsedExpiringToDoModel(
                    file: .random(),
                    line: 1,
                    fullMatch: "",
                    author: "user.name",
                    dateString: "30/12/3022"
                ),
                maxFutureDays: 365,
                allowedAuthors: ["user.name"],
                userToBeBlocked: "",
                now: now
            ),
            expectedStatus: .valid
        )
    }

    func test_expired_nonBlocking() throws {
        let now = try Date.from(string: "25.05.3022 15:59", format: "dd.MM.yy HH:mm")

        responsibilityProvider.given(.isNilAuthorAllowed(willReturn: true))
        responsibilityProvider.given(.shouldToDoBlock(
            username: .value("merge_request.author"),
            todoAuthor: .value(nil),
            willReturn: false
        ))
        check(
            try verifier.verify(
                todo: ParsedExpiringToDoModel(
                    file: .random(),
                    line: 4,
                    fullMatch: "",
                    author: nil,
                    dateString: "1.1.10"
                ),
                maxFutureDays: 365,
                allowedAuthors: [],
                userToBeBlocked: "merge_request.author",
                now: now
            ),
            expectedStatus: .expiredWarning(daysAgo: 369_770)
        )
    }

    func test_emptyAuthorNotAllowed() throws {
        let now = try Date.from(string: "25.05.3022 15:59", format: "dd.MM.yy HH:mm")

        responsibilityProvider.given(.isNilAuthorAllowed(willReturn: false))
        check(
            try verifier.verify(
                todo: ParsedExpiringToDoModel(
                    file: .random(),
                    line: 4,
                    fullMatch: "",
                    author: nil,
                    dateString: "1.1.10"
                ),
                maxFutureDays: 365,
                allowedAuthors: [],
                userToBeBlocked: "merge_request.author",
                now: now
            ),
            expectedStatus: .emptyAuthorIsNotAllowed
        )
    }
}
