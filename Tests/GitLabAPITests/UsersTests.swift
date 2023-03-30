import Combine
import Foundation
@testable import Networking
import SwiftlaneCore
import SwiftlaneUnitTestTools
import SwiftyMocky
import XCTest

@testable import GitLabAPI

class UsersTests: XCTestCase {
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

    func test_loadUserActivityEvents_singlePage() throws {
        // given
        let userId = Int.random(in: 0 ... 1000)
        let page = Int.random(in: 0 ... 1000)
        let perPage = Int.random(in: 0 ... 1000)
        let afterDate = Date()

        let route = "users/\(userId)/events"

        let dump = try Stubs.readDump(route: "users/631/events", uuid: "E5289F3E-5BB5-4D88-AC86-CE4534CB9854")

        clientMock.given(.get(.value(route), willReturn: .stub(method: .get, performRequest: { request in
            XCTAssertEqual(request.body, nil)
            XCTAssertEqual(request.timeout, nil)
            XCTAssertEqual(request.headers, [:])
            XCTAssertEqual(NSDictionary(dictionary: request.queryItems), NSDictionary(dictionary: [
                "page": page,
                "per_page": perPage,
                "after": afterDate.shortISO8601String,
            ]))
            return NetworkingResponse(
                request: request,
                urlRequest: request.buildURLRequest(logger: nil),
                urlResponse: HTTPURLResponse(),
                data: dump.responseBody.data(using: .utf8)!
            )
        })))

        // when
        let result = try api.userActivityEvents(
            userId: userId,
            after: afterDate,
            page: page,
            perPage: perPage
        ).await()

        // then
        XCTAssertEqual(result.count, 50)
    }

    func test_loadGroupMembers() throws {
        // given
        let group = GitLab.Group(id: Int.random(in: 0 ... 1000))

        let route = "groups/\(group.id)/members"

        let dump = try Stubs.readDump(route: "groups/81253/members", uuid: "21E7481F-BCAB-4955-B935-6729B10E2AF5")

        clientMock.given(.get(.value(route), willReturn: .stub(method: .get, performRequest: { request in
            XCTAssertEqual(request.body, nil)
            XCTAssertEqual(request.timeout, nil)
            XCTAssertEqual(request.headers, [:])
            XCTAssertEqual(NSDictionary(dictionary: request.queryItems), NSDictionary(dictionary: [
                "per_page": 100,
            ]))
            return NetworkingResponse(
                request: request,
                urlRequest: request.buildURLRequest(logger: nil),
                urlResponse: HTTPURLResponse(),
                data: dump.responseBody.data(using: .utf8)!
            )
        })))

        // when
        let result = try api.groupMembers(
            group: group
        ).await()

        // then
        XCTAssertEqual(result.count, 8)
    }
}
