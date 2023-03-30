import Combine
import Foundation
@testable import Networking
import SwiftlaneCore
import SwiftlaneUnitTestTools
import SwiftyMocky
import XCTest

@testable import GitLabAPI

class MergeRequestsTests: XCTestCase {
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

    func test_loadMergeRequest() throws {
        // given
        let projectId = 75700
        let mergeRequestIid = 3536
        let route = "projects/\(projectId)/merge_requests/\(mergeRequestIid)"
        let dump = try Stubs.readDump(route: route, uuid: "4A0775D4-797E-4B7F-AA25-B8E1534EED76")

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

        // when
        let result = try api.mergeRequest(
            projectId: projectId,
            mergeRequestIid: mergeRequestIid,
            loadChanges: false
        ).await()

        // then
        XCTAssertNil(result.changes)
    }

    func test_loadMergeRequestDiffs() throws {
        // given
        let projectId = 75700
        let mergeRequestIid = 4539
        let route = "projects/\(projectId)/merge_requests/\(mergeRequestIid)/changes"
        let dump = try Stubs.readDump(route: route, uuid: "6969BB67-0AE7-420F-B54B-D436044BDDBC")

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

        // when
        let result = try api.mergeRequest(
            projectId: projectId,
            mergeRequestIid: mergeRequestIid,
            loadChanges: true
        ).await()

        // then
        XCTAssertEqual(result.changes?.count, 3)
    }

    func test_loadGroupMergeRequests() throws {
        // given
        let groupId = Int.random(in: 100 ... 300)
        let route = "groups/\(groupId)/merge_requests"
        let createdAfter = Date(timeIntervalSince1970: 21_537_123)
        let authorId = Int.random(in: 0 ... 1000)
        let dump = try Stubs.readDump(route: "groups/329/merge_requests", uuid: "0E8C0E3E-ACE8-4211-9A8B-0B927156FBE1")

        clientMock.given(.get(.value(route), willReturn: .stub(method: .get, performRequest: { request in
            XCTAssertEqual(request.body, nil)
            XCTAssertEqual(request.timeout, nil)
            XCTAssertEqual(request.headers, [:])
            XCTAssertEqual(NSDictionary(dictionary: request.queryItems), NSDictionary(dictionary: [
                "author_id": authorId,
                "per_page": 100,
                "state": "all",
                "created_after": "1970-09-07T06:32:03Z",
                "scope": "all",
            ]))
            return NetworkingResponse(
                request: request,
                urlRequest: request.buildURLRequest(logger: nil),
                urlResponse: HTTPURLResponse(),
                data: dump.responseBody.data(using: .utf8)!
            )
        })))

        // when
        let result = try api.mergeRequests(
            inState: .all,
            space: .group(id: groupId),
            createdAfter: createdAfter,
            authorId: authorId
        ).await()

        // then
        XCTAssertEqual(result.count, 100)
    }

    func test_loadProjectMergeRequests() throws {
        // given
        let projectId = Int.random(in: 100 ... 300)
        let route = "projects/\(projectId)/merge_requests"
        let createdAfter = Date(timeIntervalSince1970: 21_537_123)
        let authorId = Int.random(in: 0 ... 1000)
        let dump = try Stubs.readDump(route: "groups/329/merge_requests", uuid: "0E8C0E3E-ACE8-4211-9A8B-0B927156FBE1")

        clientMock.given(.get(.value(route), willReturn: .stub(method: .get, performRequest: { request in
            XCTAssertEqual(request.body, nil)
            XCTAssertEqual(request.timeout, nil)
            XCTAssertEqual(request.headers, [:])
            XCTAssertEqual(NSDictionary(dictionary: request.queryItems), NSDictionary(dictionary: [
                "author_id": authorId,
                "per_page": 100,
                "state": "all",
                "created_after": "1970-09-07T06:32:03Z",
                "scope": "all",
            ]))
            return NetworkingResponse(
                request: request,
                urlRequest: request.buildURLRequest(logger: nil),
                urlResponse: HTTPURLResponse(),
                data: dump.responseBody.data(using: .utf8)!
            )
        })))

        // when
        let result = try api.mergeRequests(
            inState: .all,
            space: .project(id: projectId),
            createdAfter: createdAfter,
            authorId: authorId
        ).await()

        // then
        XCTAssertEqual(result.count, 100)
    }

    func test_loadAllMergeRequests() throws {
        // given
        let route = "merge_requests"
        let createdAfter = Date(timeIntervalSince1970: 21_537_123)
        let authorId = Int.random(in: 0 ... 1000)
        let dump = try Stubs.readDump(route: "groups/329/merge_requests", uuid: "0E8C0E3E-ACE8-4211-9A8B-0B927156FBE1")

        clientMock.given(.get(.value(route), willReturn: .stub(method: .get, performRequest: { request in
            XCTAssertEqual(request.body, nil)
            XCTAssertEqual(request.timeout, nil)
            XCTAssertEqual(request.headers, [:])
            XCTAssertEqual(NSDictionary(dictionary: request.queryItems), NSDictionary(dictionary: [
                "author_id": authorId,
                "per_page": 100,
                "state": "all",
                "created_after": "1970-09-07T06:32:03Z",
                "scope": "all",
            ]))
            return NetworkingResponse(
                request: request,
                urlRequest: request.buildURLRequest(logger: nil),
                urlResponse: HTTPURLResponse(),
                data: dump.responseBody.data(using: .utf8)!
            )
        })))

        // when
        let result = try api.mergeRequests(
            inState: .all,
            space: .everywhere,
            createdAfter: createdAfter,
            authorId: authorId
        ).await()

        // then
        XCTAssertEqual(result.count, 100)
    }

    func test_loadMergeRequestNotes() throws {
        // given
        let projectId = Int.random(in: 0 ... 1000)
        let mergeRequestIid = Int.random(in: 0 ... 1000)
        let route = "/projects/\(projectId)/merge_requests/\(mergeRequestIid)/notes"
        let dump = try Stubs.readDump(
            route: "projects/75700/merge_requests/3536/notes",
            uuid: "2F165EF9-F422-48BB-BC9B-F5F49B88C3DF"
        )

        clientMock.given(.get(.value(route), willReturn: .stub(method: .get, performRequest: { request in
            XCTAssertEqual(request.body, nil)
            XCTAssertEqual(request.timeout, nil)
            XCTAssertEqual(request.headers, [:])
            XCTAssertEqual(NSDictionary(dictionary: request.queryItems), NSDictionary(dictionary: [
                "order_by": "created_at",
                "per_page": 100,
                "sort": "desc",
            ]))
            return NetworkingResponse(
                request: request,
                urlRequest: request.buildURLRequest(logger: nil),
                urlResponse: HTTPURLResponse(),
                data: dump.responseBody.data(using: .utf8)!
            )
        })))

        // when
        let result = try api.mergeRequestNotes(
            projectId: projectId,
            mergeRequestIid: mergeRequestIid,
            orderBy: .createdAt,
            sorting: .descending
        ).await()

        // then
        XCTAssertEqual(result.count, 20)
    }
}

extension NetworkingRequestBuilder {
    static func stub(
        method: HTTPMethod,
        performRequest: @escaping (NetworkingRequest) -> NetworkingResponse
    ) -> NetworkingRequestBuilder {
        NetworkingRequestBuilder(
            method: method,
            baseURL: .random(),
            route: .random(),
            serializer: JSONSerializer(encoder: .snakeCaseConverting),
            deserializer: GitLabAPIDeserializer()
        ) { request in
            Just(.result(performRequest(request)))
                .setFailureType(to: NetworkingError.self)
                .eraseToAnyPublisher()
        }
    }
}
