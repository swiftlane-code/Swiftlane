import Combine
import Foundation
@testable import Networking
import SwiftlaneCore
import SwiftlaneUnitTestTools
import SwiftyMocky
import XCTest

@testable import GitLabAPI

class ApprovalRulesTests: XCTestCase {
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

    func test_projectApprovalRules() throws {
        // given
        let projectId = Int.random(in: 0 ... 1000)
        let route = "projects/\(projectId)/approval_rules"
        let dump = try Stubs.readDump(route: "projects/75700/approval_rules", uuid: "7DB4E79E-9121-4019-99E8-415168E63090")

        clientMock.given(.get(.value(route), willReturn: .stub(method: .get, performRequest: { request in
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
        let result = try api.projectApprovalRules(projectId: projectId).await()

        // then
        XCTAssertEqual(result.count, 3)
    }

    func test_mergeRequestAllApprovalRules() throws {
        // given
        let projectId = Int.random(in: 0 ... 1000)
        let mergeRequestIid = Int.random(in: 0 ... 1000)
        let route = "projects/\(projectId)/merge_requests/\(mergeRequestIid)/approval_rules"
        let dump = try Stubs.readDump(route: "projects/75700/approval_rules", uuid: "7DB4E79E-9121-4019-99E8-415168E63090")

        clientMock.given(.get(.value(route), willReturn: .stub(method: .get, performRequest: { request in
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
        let result = try api.mergeRequestApprovalRulesAll(projectId: projectId, mergeRequestIid: mergeRequestIid).await()

        // then
        XCTAssertEqual(result.count, 3)
    }

    func test_mergeRequestLeftApprovalRules() throws {
        // given
        let projectId = Int.random(in: 0 ... 1000)
        let mergeRequestIid = Int.random(in: 0 ... 1000)
        let route = "projects/\(projectId)/merge_requests/\(mergeRequestIid)/approvals"
        let dump = try Stubs.readDump(
            route: "projects/75700/merge_requests/4539/approvals",
            uuid: "3F209A32-B6DD-41A1-9B3F-8CDEDC18F1AE"
        )

        clientMock.given(.get(.value(route), willReturn: .stub(method: .get, performRequest: { request in
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
        let result = try api.mergeRequestApprovalRulesLeft(projectId: projectId, mergeRequestIid: mergeRequestIid).await()

        // then
        XCTAssertEqual(result.approvalsLeft, 1)
    }
}
