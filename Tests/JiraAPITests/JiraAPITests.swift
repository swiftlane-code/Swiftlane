//

import Combine
import Foundation
@testable import JiraAPI
@testable import Networking
import SwiftlaneCore
import SwiftyMocky
import XCTest

class JiraAPITests: XCTestCase {
    var api: JiraAPIClient!
    var clientMock: NetworkingClientProtocolMock!

    override func setUpWithError() throws {
        try super.setUpWithError()

        clientMock = NetworkingClientProtocolMock(stubbing: .drop)
        api = JiraAPIClient(networkingClient: clientMock as NetworkingClientProtocol)
    }

    override func tearDown() {
        super.tearDown()

        api = nil
    }

    func test_loadIssue() throws {
        // given
        let route = "issue/MDDS-3980"
        let issueKey = "MDDS-3980"
        let dump = try Stubs.readDump(route: route, uuid: "1639B0A4-354B-45E5-A3B4-9A37D8A69A98")

        clientMock.given(.get(.value(route), willReturn: .stub(method: .get, performRequest: { request in
            XCTAssertEqual(request.body, nil)
            XCTAssertEqual(request.timeout, nil)
            XCTAssertEqual(request.headers, [:])
            XCTAssertEqual(request.queryItems as? [String: String], [:])
            return NetworkingResponse(
                request: request,
                urlRequest: request.buildURLRequest(logger: nil),
                urlResponse: HTTPURLResponse(),
                data: dump.responseBody.data(using: .utf8)!
            )
        })))

        // when
        let result = try api.loadIssue(issueKey: issueKey).await()

        // then
        XCTAssertEqual(result.key, issueKey)
        XCTAssertEqual(result.fields.allData.count, 210)
    }

    func test_loadIssueTransitions() throws {
        // given
        let route = "issue/MDDS-3980/transitions"
        let issueKey = "MDDS-3980"
        let dump = try Stubs.readDump(route: route, uuid: "31A349BC-A866-446F-AF8C-380548A2544A")

        clientMock.given(.get(.value(route), willReturn: .stub(method: .get, performRequest: { request in
            XCTAssertEqual(request.body, nil)
            XCTAssertEqual(request.timeout, nil)
            XCTAssertEqual(request.headers, [:])
            XCTAssertEqual(request.queryItems as? [String: String], [:])
            return NetworkingResponse(
                request: request,
                urlRequest: request.buildURLRequest(logger: nil),
                urlResponse: HTTPURLResponse(),
                data: dump.responseBody.data(using: .utf8)!
            )
        })))

        // when
        let result = try api.loadTransitions(issueKey: issueKey).await()

        // then
        XCTAssertEqual(result.transitions.count, 6)
    }

    func test_loadProjectVersions() throws {
        // given
        let route = "project/MDDS/versions"
        let projectKey = "MDDS"
        let dump = try Stubs.readDump(route: route, uuid: "9CE45543-6DF0-4E51-A74F-46407256FAB3")

        clientMock.given(.get(.value(route), willReturn: .stub(method: .get, performRequest: { request in
            XCTAssertEqual(request.body, nil)
            XCTAssertEqual(request.timeout, nil)
            XCTAssertEqual(request.headers, [:])
            XCTAssertEqual(request.queryItems as? [String: String], [:])
            return NetworkingResponse(
                request: request,
                urlRequest: request.buildURLRequest(logger: nil),
                urlResponse: HTTPURLResponse(),
                data: dump.responseBody.data(using: .utf8)!
            )
        })))

        // when
        let result = try api.versions(projectKey: projectKey).await()

        // then
        XCTAssertEqual(result.count, 3)
    }

    func test_loadVersionDetails() throws {
        // given
        let versionId = "10561"
        let route = "version/" + versionId
        let dump = try Stubs.readDump(route: route, uuid: "D41C3AE6-F7C5-4CD7-9494-E90B335712C3")

        clientMock.given(.get(.value(route), willReturn: .stub(method: .get, performRequest: { request in
            XCTAssertEqual(request.body, nil)
            XCTAssertEqual(request.timeout, nil)
            XCTAssertEqual(request.headers, [:])
            XCTAssertEqual(request.queryItems as? [String: String], ["expand": "issuesstatus"])
            return NetworkingResponse(
                request: request,
                urlRequest: request.buildURLRequest(logger: nil),
                urlResponse: HTTPURLResponse(),
                data: dump.responseBody.data(using: .utf8)!
            )
        })))

        // when
        let result = try api.loadDetailVersion(version: versionId).await()

        // then
        XCTAssertEqual(result.name, "6.14")
    }

    func test_loadSearchDemandLabel() throws {
        // given
        let route = "search"
        let dump = try Stubs.readDump(route: route, uuid: "52554490-56DC-426A-A53D-1A521F87A18A")

        clientMock.given(.post(.value(route), willReturn: .stub(method: .post, performRequest: { request in
            XCTAssertEqual(request.timeout, nil)
            XCTAssertEqual(request.headers, [:])
            XCTAssertEqual(request.queryItems as? [String: String], [:])
            return NetworkingResponse(
                request: request,
                urlRequest: request.buildURLRequest(logger: nil),
                urlResponse: HTTPURLResponse(),
                data: dump.responseBody.data(using: .utf8)!
            )
        })))

        // when
        let result = try api.search(jql: JiraJQL(projectKey: "MDDS").labels("Demand")).await()

        // then
        XCTAssertEqual(result.issues.count, 27)
    }

    func test_loadSearchSuitableForMovingVersion() throws {
        // given
        let route = "search"
        let dump = try Stubs.readDump(route: route, uuid: "52554490-56DC-426A-A53D-1A521F87A18A")

        clientMock.given(.post(.value(route), willReturn: .stub(method: .post, performRequest: { request in
            XCTAssertEqual(request.timeout, nil)
            XCTAssertEqual(request.headers, [:])
            XCTAssertEqual(request.queryItems as? [String: String], [:])
            return NetworkingResponse(
                request: request,
                urlRequest: request.buildURLRequest(logger: nil),
                urlResponse: HTTPURLResponse(),
                data: dump.responseBody.data(using: .utf8)!
            )
        })))

        // when
        let result = try api.search(jql: JiraJQL(projectKey: "MDDS").version("6.14")).await()

        // then
        XCTAssertEqual(result.issues.count, 27)
    }

    func test_setField() throws {
        // given
        let route = "issue/MDDS-1000"

        clientMock.given(.put(.value(route), willReturn: .stub(method: .put, performRequest: { request in
            let bodyText = request.body.flatMap { String(data: $0, encoding: .utf8) }
            XCTAssertEqual(
                bodyText,
                #"{"fields":{"customfield_123456":null}}"#
            )
            XCTAssertEqual(request.timeout, nil)
            XCTAssertEqual(request.headers, [:])
            XCTAssertEqual(request.queryItems as? [String: String], [:])
            return NetworkingResponse(
                request: request,
                urlRequest: request.buildURLRequest(logger: nil),
                urlResponse: HTTPURLResponse(),
                data: "".data(using: .utf8)!
            )
        })))

        // when
        try api.setField(issueKey: "MDDS-1000", fieldKey: "customfield_123456", value: AnyEncodable(String?.none)).await()

        // then
    }
}

extension NetworkingRequestBuilder {
    static func stub(
        method: HTTPMethod,
        performRequest: @escaping (NetworkingRequest) -> NetworkingResponse
    ) -> NetworkingRequestBuilder {
        NetworkingRequestBuilder(
            method: method,
            baseURL: .stub(),
            route: .stub(),
            serializer: JiraAPISerializer(),
            deserializer: JiraAPIDeserializer()
        ) { request in
            Just(.result(performRequest(request)))
                .setFailureType(to: NetworkingError.self)
                .eraseToAnyPublisher()
        }
    }
}

extension String {
    static func stub() -> String {
        UUID().uuidString
    }
}

extension URL {
    static func stub() -> URL {
        URL(string: UUID().uuidString)!
    }
}
