//

import Combine
import Foundation
import GitLabAPI
import Networking
import SwiftlaneCoreMocks
import SwiftlaneUnitTestTools
import XCTest

@testable import Guardian

class MergeRequestReporterTests: XCTestCase {
    var reporter: GitLabMergeRequestReporter!
    var logger: LoggingMock!
    var gitlabApi: GitLabAPIClientProtocolMock!
    var gitlabCIEnvironment: GitLabCIEnvironmentReadingMock!
    var reportFactory: MergeRequestReportFactoringMock!

    override func setUp() {
        super.setUp()

        logger = .init()
        gitlabApi = .init()
        gitlabCIEnvironment = .init()
        reportFactory = .init()

        reporter = .init(
            logger: logger,
            gitlabApi: gitlabApi,
            gitlabCIEnvironment: gitlabCIEnvironment,
            reportFactory: reportFactory,
            publishEmptyReport: true,
            commentIdentificator: "guardian"
        )

        logger.given(.logLevel(getter: .verbose))
    }

    override func tearDown() {
        reporter = nil

        logger = nil
        gitlabApi = nil
        gitlabCIEnvironment = nil
        reportFactory = nil

        super.tearDown()
    }

    func test_updateExistingNote() throws {
        // given
        let commitSHA = "commitSHA_" + .random()
        let projectId = Int.random(in: 0 ... 10000)
        let mergeRequestIid = Int.random(in: 0 ... 10000)
        let body = "body_" + .random()
        let projectURL = "projectURL_" + .random()

        let existingNotes: [MergeRequest.Note] = [
            .stub(),
            .stub(body: UUID().uuidString + "<!-- guardian -->" + UUID().uuidString),
            .stub(),
            .stub(),
        ]

        let editableNoteId = existingNotes[1].id

        gitlabCIEnvironment.given(.int(.value(.CI_PROJECT_ID), willReturn: projectId))
        gitlabCIEnvironment.given(.int(.value(.CI_MERGE_REQUEST_IID), willReturn: mergeRequestIid))
        gitlabCIEnvironment.given(.string(.value(.CI_COMMIT_SHA), willReturn: commitSHA))
        gitlabCIEnvironment.given(.string(.value(.CI_PROJECT_URL), willReturn: projectURL))

        gitlabApi.given(
            .mergeRequestNotes(
                projectId: .value(projectId),
                mergeRequestIid: .value(mergeRequestIid),
                orderBy: .value(.createdAt),
                sorting: .value(.descending),
                willReturn: .just(existingNotes)
            )
        )

        gitlabApi.given(
            .setMergeRequestNote(
                projectId: .value(projectId),
                mergeRequestIid: .value(mergeRequestIid),
                noteId: .value(editableNoteId),
                body: .matching(
                    {
                        XCTAssertEqual($0, body)
                        return true
                    }
                ),
                willReturn: .just(.stub())
            )
        )

        reportFactory.given(
            .reportBody(
                fails: .value([]),
                warns: .value([]),
                messages: .value([]),
                markdowns: .value([]),
                successes: .value([]),
                invisibleMark: .value("<!-- guardian -->"),
                commitSHA: .value(commitSHA),
                willReturn: body
            )
        )

        // when
        try reporter.createOrUpdateReport()

        // then
        gitlabApi.verify(.setMergeRequestNote(projectId: .any, mergeRequestIid: .any, noteId: .any, body: .any), count: .once)
        gitlabApi.verify(.createMergeRequestNote(projectId: .any, mergeRequestIid: .any, body: .any), count: .never)
    }

    func test_createNewNote() throws {
        // given
        let commitSHA = "commitSHA_" + .random()
        let projectId = Int.random(in: 0 ... 10000)
        let mergeRequestIid = Int.random(in: 0 ... 10000)
        let body = "body_" + .random()
        let projectURL = "projectURL_" + .random()

        gitlabCIEnvironment.given(.int(.value(.CI_PROJECT_ID), willReturn: projectId))
        gitlabCIEnvironment.given(.int(.value(.CI_MERGE_REQUEST_IID), willReturn: mergeRequestIid))
        gitlabCIEnvironment.given(.string(.value(.CI_COMMIT_SHA), willReturn: commitSHA))
        gitlabCIEnvironment.given(.string(.value(.CI_PROJECT_URL), willReturn: projectURL))

        gitlabApi.given(
            .mergeRequestNotes(
                projectId: .value(projectId),
                mergeRequestIid: .value(mergeRequestIid),
                orderBy: .any,
                sorting: .any,
                willReturn: .just([])
            )
        )

        let createdNote = MergeRequest.Note.stub()

        gitlabApi.given(
            .createMergeRequestNote(
                projectId: .value(projectId),
                mergeRequestIid: .value(mergeRequestIid),
                body: .matching(
                    {
                        XCTAssertEqual($0, body)
                        return true
                    }
                ),
                willReturn: .just(createdNote)
            )
        )

        let warn = "warn"
        let message = "message"
        let success = "success"
        let markdown = "markdown"

        reporter.warn(warn)
        reporter.message(message)
        reporter.success(success)
        reporter.markdown(markdown)

        reportFactory.given(
            .reportBody(
                fails: .value([]),
                warns: .value([warn]),
                messages: .value([message]),
                markdowns: .value([markdown]),
                successes: .value([success]),
                invisibleMark: .value("<!-- guardian -->"),
                commitSHA: .value(commitSHA),
                willReturn: body
            )
        )

        // when
        try reporter.createOrUpdateReport()

        // then
        gitlabApi.verify(
            .setMergeRequestNote(projectId: .any, mergeRequestIid: .any, noteId: .any, body: .any),
            count: .never
        )
        gitlabApi.verify(.createMergeRequestNote(projectId: .any, mergeRequestIid: .any, body: .any), count: .once)
    }

    func test_throwsErrorWhenFailIsReported() throws {
        // given
        let commitSHA = "commitSHA_" + .random()
        let projectId = Int.random(in: 0 ... 10000)
        let mergeRequestIid = Int.random(in: 0 ... 10000)
        let body = "body_" + .random()
        let projectURL = "projectURL_" + .random()

        let createdNote = MergeRequest.Note.stub()
        let expectedError = GitLabMergeRequestReporter.Errors.failsReported(
            reportURL: "\(projectURL)/-/merge_requests/\(mergeRequestIid)#note_\(createdNote.id)"
        )

        gitlabCIEnvironment.given(.int(.value(.CI_PROJECT_ID), willReturn: projectId))
        gitlabCIEnvironment.given(.int(.value(.CI_MERGE_REQUEST_IID), willReturn: mergeRequestIid))
        gitlabCIEnvironment.given(.string(.value(.CI_COMMIT_SHA), willReturn: commitSHA))
        gitlabCIEnvironment.given(.string(.value(.CI_PROJECT_URL), willReturn: projectURL))

        gitlabApi.given(
            .mergeRequestNotes(
                projectId: .value(projectId),
                mergeRequestIid: .value(mergeRequestIid),
                orderBy: .any,
                sorting: .any,
                willReturn: .just([])
            )
        )

        gitlabApi.given(
            .createMergeRequestNote(
                projectId: .value(projectId),
                mergeRequestIid: .value(mergeRequestIid),
                body: .matching(
                    {
                        XCTAssertEqual($0, body)
                        return true
                    }
                ),
                willReturn: .just(createdNote)
            )
        )

        let fail = "fail"

        reportFactory.given(
            .reportBody(
                fails: .value([fail]),
                warns: .value([]),
                messages: .value([]),
                markdowns: .value([]),
                successes: .value([]),
                invisibleMark: .value("<!-- guardian -->"),
                commitSHA: .value(commitSHA),
                willReturn: body
            )
        )

        reporter.fail(fail)

        // when
        XCTAssertThrowsError(try reporter.createOrUpdateReport()) { error in
            // then
            XCTAssertEqual(error as! GitLabMergeRequestReporter.Errors, expectedError)
        }
    }

    func test_hasFails() {
        reporter.message(#function)
        XCTAssertFalse(reporter.hasFails())

        reporter.warn(#function)
        XCTAssertFalse(reporter.hasFails())

        reporter.markdown(#function)
        XCTAssertFalse(reporter.hasFails())

        reporter.success(#function)
        XCTAssertFalse(reporter.hasFails())

        reporter.fail(#function)
        XCTAssertTrue(reporter.hasFails())
    }
}

private extension MergeRequest.Note {
    static func stub(body: String? = nil) -> MergeRequest.Note {
        .init(
            id: .random(in: 0 ... 1000),
            body: body ?? UUID().uuidString,
            author: .stub(),
            createdAt: Date(),
            updatedAt: Date(),
            system: .random(),
            noteableId: .random(in: 0 ... 1000),
            noteableType: UUID().uuidString,
            noteableIid: .random(in: 0 ... 1000),
            resolvable: .random(),
            confidential: .random()
        )
    }
}

private extension Member {
    static func stub() -> Member {
        .init(
            id: Int.random(in: 0 ... 1000),
            name: UUID().uuidString,
            username: UUID().uuidString,
            state: UUID().uuidString,
            avatarUrl: UUID().uuidString,
            webUrl: UUID().uuidString
        )
    }
}
