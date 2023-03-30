import Combine
import Foundation
@testable import Networking
import SwiftlaneCore
import SwiftlaneUnitTestTools
import SwiftyMocky
import XCTest

@testable import GitLabAPI

class EditMergeRequestsTests: XCTestCase {
    var api: GitLabAPIClient!
    var clientMock: NetworkingClientProtocolMock!

    override func setUpWithError() throws {
        try super.setUpWithError()

        clientMock = NetworkingClientProtocolMock(stubbing: .drop)
        api = GitLabAPIClient(networkingClient: clientMock as NetworkingClientProtocol)
    }

    override func tearDown() {
        super.tearDown()

        api = nil
    }

    func test_createMergeRequestNote() throws {
        // given
        let projectId = Int.random(in: 0 ... 1000)
        let mergeRequestIid = Int.random(in: 0 ... 1000)
        let route = "/projects/\(projectId)/merge_requests/\(mergeRequestIid)/notes"
        let dump = try Stubs.readDump(
            route: "projects/75700/merge_requests/3536/notes",
            uuid: "0BBB909D-90F8-4462-9C02-6CA37727FFF6"
        )
        let body = "##some\nnote|\nmultiline"

        clientMock.given(.post(.value(route), willReturn: .stub(method: .get, performRequest: { request in
            XCTAssertEqual(request.queryItems.count, 0)
            XCTAssertEqual(request.timeout, nil)
            XCTAssertEqual(request.headers, [:])
            XCTAssertEqual(String(data: request.body!, encoding: .utf8), "{\"body\":\"##some\\nnote|\\nmultiline\"}")
            return NetworkingResponse(
                request: request,
                urlRequest: request.buildURLRequest(logger: nil),
                urlResponse: HTTPURLResponse(),
                data: dump.responseBody.data(using: .utf8)!
            )
        })))

        // when
        let result = try api.createMergeRequestNote(
            projectId: projectId,
            mergeRequestIid: mergeRequestIid,
            body: body
        ).await()

        // then
        XCTAssertEqual(result.id, 434_124)
    }

    func test_setMergeRequestNote() throws {
        // given
        let projectId = Int.random(in: 0 ... 1000)
        let mergeRequestIid = Int.random(in: 0 ... 1000)
        let noteId = Int.random(in: 0 ... 1000)
        let route = "/projects/\(projectId)/merge_requests/\(mergeRequestIid)/notes/\(noteId)"
        let dump = try Stubs.readDump(
            route: "projects/75700/merge_requests/3536/notes/434124",
            uuid: "CB1BD4B1-5386-49E2-8394-4E2DE5468BE3"
        )
        let body = "##some\nnote|\nmultiline"

        clientMock.given(.put(.value(route), willReturn: .stub(method: .get, performRequest: { request in
            XCTAssertEqual(request.queryItems.count, 0)
            XCTAssertEqual(request.timeout, nil)
            XCTAssertEqual(request.headers, [:])
            XCTAssertEqual(String(data: request.body!, encoding: .utf8), "{\"body\":\"##some\\nnote|\\nmultiline\"}")
            return NetworkingResponse(
                request: request,
                urlRequest: request.buildURLRequest(logger: nil),
                urlResponse: HTTPURLResponse(),
                data: dump.responseBody.data(using: .utf8)!
            )
        })))

        // when
        let result = try api.setMergeRequestNote(
            projectId: projectId,
            mergeRequestIid: mergeRequestIid,
            noteId: noteId,
            body: body
        ).await()

        // then
        XCTAssertEqual(result.id, 434_124)
    }

    func test_deleteMergeRequestNote() throws {
        // given
        let projectId = Int.random(in: 0 ... 1000)
        let mergeRequestIid = Int.random(in: 0 ... 1000)
        let noteId = Int.random(in: 0 ... 1000)
        let route = "/projects/\(projectId)/merge_requests/\(mergeRequestIid)/notes/\(noteId)"
        let dump = try Stubs.readDump(
            route: "projects/75700/merge_requests/3536/notes/434124",
            uuid: "ACBFAC5C-7573-4F3E-ACE7-E2271EC4548E"
        )

        clientMock.given(.delete(.value(route), willReturn: .stub(method: .get, performRequest: { request in
            XCTAssertEqual(request.body, nil)
            XCTAssertEqual(request.timeout, nil)
            XCTAssertEqual(request.headers, [:])
            XCTAssertEqual(NSDictionary(dictionary: request.queryItems), NSDictionary(dictionary: [:]))
            return NetworkingResponse(
                request: request,
                urlRequest: request.buildURLRequest(logger: nil),
                urlResponse: HTTPURLResponse(),
                data: dump.responseBody.data(using: .utf8)!
            )
        })))

        // when
        try api.deleteMergeRequestNote(
            projectId: projectId,
            mergeRequestIid: mergeRequestIid,
            noteId: noteId
        ).await()
    }

    func test_setMergeRequestAssignee() throws {
        // given
        let projectId = Int.random(in: 0 ... 1000)
        let mergeRequestIid = Int.random(in: 0 ... 1000)
        let assigneeId = Int.random(in: 0 ... 1000)
        let route = "projects/\(projectId)/merge_requests/\(mergeRequestIid)"
        let dump = try Stubs.readDump(
            route: "/projects/75700/merge_requests/3536",
            uuid: "4A0775D4-797E-4B7F-AA25-B8E1534EED76"
        )

        clientMock.given(.put(.value(route), willReturn: .stub(method: .get, performRequest: { request in
            XCTAssertEqual(String(data: request.body!, encoding: .utf8)!, "{\"assignee_ids\":[\(assigneeId)]}")
            XCTAssertEqual(request.timeout, nil)
            XCTAssertEqual(request.headers, [:])
            XCTAssertEqual(NSDictionary(dictionary: request.queryItems), NSDictionary(dictionary: [:]))
            return NetworkingResponse(
                request: request,
                urlRequest: request.buildURLRequest(logger: nil),
                urlResponse: HTTPURLResponse(),
                data: dump.responseBody.data(using: .utf8)!
            )
        })))

        // when
        let _ = try api.setMergeRequest(
            projectId: projectId,
            mergeRequestIid: mergeRequestIid,
            assigneeId: assigneeId
        ).await()
    }

    func test_setMergeRequestLabels() throws {
        // given
        let projectId = Int.random(in: 0 ... 1000)
        let mergeRequestIid = Int.random(in: 0 ... 1000)
        let labels = ["release", "test_label_1", "test_label_2"]
        let route = "projects/\(projectId)/merge_requests/\(mergeRequestIid)"
        let dump = try Stubs.readDump(
            route: "/projects/75700/merge_requests/3536",
            uuid: "4A0775D4-797E-4B7F-AA25-B8E1534EED76"
        )

        // load current merge request labels
        clientMock.given(.get(.value(route), willReturn: .stub(method: .get, performRequest: { request in
            XCTAssertEqual(request.body, nil)
            XCTAssertEqual(request.timeout, nil)
            XCTAssertEqual(request.headers, [:])
            XCTAssertEqual("\(request.queryItems)", #"["access_raw_diffs": true]"#)
            return NetworkingResponse(
                request: request,
                urlRequest: request.buildURLRequest(logger: nil),
                urlResponse: HTTPURLResponse(),
                data: dump.responseBody.data(using: .utf8)!
            )
        })))

        // set labels
        clientMock.given(.put(.value(route), willReturn: .stub(method: .get, performRequest: { request in
            let body = try! JSONDecoder().decode([String: String].self, from: request.body!)
            XCTAssertEqual(body, ["add_labels": "test_label_1,test_label_2", "remove_labels": "WIP,bug,core"])
            XCTAssertEqual(request.timeout, nil)
            XCTAssertEqual(request.headers, [:])
            XCTAssertEqual(NSDictionary(dictionary: request.queryItems), NSDictionary(dictionary: [:]))
            return NetworkingResponse(
                request: request,
                urlRequest: request.buildURLRequest(logger: nil),
                urlResponse: HTTPURLResponse(),
                data: dump.responseBody.data(using: .utf8)!
            )
        })))

        // when
        let _ = try api.setMergeRequest(
            projectId: projectId,
            mergeRequestIid: mergeRequestIid,
            labels: labels
        ).await()
    }
}
