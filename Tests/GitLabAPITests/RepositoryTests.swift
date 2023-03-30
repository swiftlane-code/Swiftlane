import Combine
import Foundation
@testable import Networking
import SwiftlaneCore
import SwiftlaneUnitTestTools
import SwiftyMocky
import XCTest

@testable import GitLabAPI

class RepositoryTests: XCTestCase {
    var api: GitLabAPIClient!
    var clientMock: NetworkingClientProtocolMock!
    var serializer: SerializerProtocol!

    override func setUpWithError() throws {
        try super.setUpWithError()

        clientMock = NetworkingClientProtocolMock(stubbing: .drop)
        api = GitLabAPIClient(networkingClient: clientMock as NetworkingClientProtocol)
        serializer = JSONSerializer(encoder: .snakeCaseConverting)
    }

    override func tearDown() {
        super.tearDown()

        api = nil
        serializer = nil
    }

    func test_loadFile() throws {
        // given
        let projectId = 75700
        let filePath = "SomeDir/SomeFile.swift"
        let ref = "feature/some-feature-branch"
        let fileData = "File Contents".data(using: .utf8)!
        let route =
            "projects/\(projectId)/repository/files/\(filePath.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)"
        let fileContent = FileContent(commitId: "", content: fileData)
        let givenData = try serializer.serialize(fileContent)

        clientMock.given(.get(.value(route), willReturn: .stub(method: .get, performRequest: { request in
            XCTAssertEqual(request.body, nil)
            XCTAssertEqual(request.timeout, nil)
            XCTAssertEqual(request.headers, [:])
            XCTAssertEqual("\(request.queryItems)", #"["ref": "feature/some-feature-branch"]"#)
            return NetworkingResponse(
                request: request,
                urlRequest: request.buildURLRequest(logger: nil),
                urlResponse: HTTPURLResponse(),
                data: givenData
            )
        })))

        // when
        let result = try api.loadRepositoryFile(
            path: filePath,
            projectId: projectId,
            ref: ref
        ).await()

        // then
        XCTAssertEqual(result.content, fileData)
    }

    func test_loadDiff() throws {
        // given
        let projectId = 75700
        let ref1 = "feature/some-feature-branch-1"
        let ref2 = "feature/some-feature-branch-2"
        let route = "projects/\(projectId)/repository/compare"
        let dump = try Stubs.readDump(route: "projects/333/repository/compare", uuid: "5A6DD82F-378D-4585-9501-E227372390FD")

        clientMock.given(.get(.value(route), willReturn: .stub(method: .get, performRequest: { request in
            XCTAssertEqual(request.body, nil)
            XCTAssertEqual(request.timeout, nil)
            XCTAssertEqual(request.headers, [:])
            XCTAssertEqual(request.queryItems as? [String: String], [
                "to": "feature/some-feature-branch-1",
                "from": "feature/some-feature-branch-2",
            ])
            return NetworkingResponse(
                request: request,
                urlRequest: request.buildURLRequest(logger: nil),
                urlResponse: HTTPURLResponse(),
                data: dump.responseBody.data(using: .utf8)!
            )
        })))

        // when
        let result = try api.repositoryDiff(projectId: projectId, source: ref1, target: ref2).await()

        // then
        XCTAssertEqual(result.diffs.count, 1)
    }
}
