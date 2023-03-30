//

import Combine
import Foundation
import XCTest

import Networking

struct Post: Codable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

class NetworkingTests: XCTestCase {
    var client: NetworkingClient!
    var subs: [AnyCancellable] = []

    private let timeout: TimeInterval = 15

    override func setUp() {
        super.setUp()

        client = NetworkingClient(baseURL: URL(string: "https://jsonplaceholder.typicode.com")!)
    }

    override func tearDown() {
        super.tearDown()

        subs.removeAll()
        client = nil
    }

    func test_GET_postsArray() {
        let exp = expectation(description: "Request finished")

        client.get("posts").perform()
            .sink { result in
                switch result {
                case let .failure(error):
                    XCTFail(String(reflecting: error))
                    XCTFail(error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: { (value: [Post]) in
                XCTAssertEqual(value.count, 100)
                exp.fulfill()
            }
            .store(in: &subs)

        wait(for: [exp], timeout: timeout)
    }

    func test_POST_createNewPost() throws {
        client.commonHeaders = [
            "Content-type": "application/json",
            "charset": "UTF-8",
        ]

        let newPost = Post(userId: 45, id: -1, title: "fake title", body: "fake body")

        let exp = expectation(description: "Request finished")

        let request = client
            .post("posts")
            .with(body: newPost)

        request.perform()
            .sink { result in
                switch result {
                case let .failure(error):
                    XCTFail(String(reflecting: error))
                    XCTFail(error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: { (value: Post) in
                debugPrint(value)
                XCTAssertEqual(value.body, newPost.body)
                exp.fulfill()
            }
            .store(in: &subs)

        wait(for: [exp], timeout: timeout)
    }

    func test_GET_withQueryItems() {
        client.commonHeaders = [
            "Content-type": "application/json",
            "charset": "UTF-8",
        ]

        let exp = expectation(description: "Request finished")

        let request = client
            .get("posts")
            .with(queryItems: ["userId": 7])

        request.perform()
            .sink { result in
                switch result {
                case let .failure(error):
                    XCTFail(String(reflecting: error))
                    XCTFail(error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: { (value: [Post]) in
                debugPrint(value)
                XCTAssertEqual(value.count, 10)
                exp.fulfill()
            }
            .store(in: &subs)

        wait(for: [exp], timeout: timeout)
    }

    func test_GET_rawStringResponse() {
        client.commonHeaders = [
            "Content-type": "application/json",
            "charset": "UTF-8",
        ]

        let exp = expectation(description: "Request finished")

        let request = client
            .get("posts")
            .with(queryItems: ["userId": 7])

        request.perform()
            .sink { result in
                switch result {
                case let .failure(error):
                    XCTFail(String(reflecting: error))
                    XCTFail(error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: { (value: String) in
                debugPrint(value)
                XCTAssertEqual(value.count, 2761)
                exp.fulfill()
            }
            .store(in: &subs)

        wait(for: [exp], timeout: timeout)
    }

    func test_DELETE() {
        client.commonHeaders = [
            "Content-type": "application/json",
            "charset": "UTF-8",
        ]

        let exp = expectation(description: "Request finished")

        let request = client.delete("posts/1")

        request.perform()
            .sink { result in
                switch result {
                case let .failure(error):
                    XCTFail(String(reflecting: error))
                    XCTFail(error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: { (_: Void) in
                debugPrint("ok")
                exp.fulfill()
            }
            .store(in: &subs)

        wait(for: [exp], timeout: timeout)
    }

    func test_DELETE_wrongAPIUsage_throwsError() {
        client.commonHeaders = [
            "Content-type": "application/json",
            "charset": "UTF-8",
        ]

        let exp = expectation(description: "Request finished")

        let request = client.delete("posts")

        request.perform()
            .sink { result in
                switch result {
                case let .failure(error):
                    if case .badStatusCode = error {
                        exp.fulfill()
                    } else {
                        XCTFail()
                    }
                case .finished:
                    XCTFail("finished without error")
                }
            } receiveValue: { (_: Void) in
                XCTFail()
            }
            .store(in: &subs)

        wait(for: [exp], timeout: timeout)
    }

    func _disabled_test_progress() throws {
        let request = URLRequest(
            url: URL(string: "http://ipv4.download.thinkbroadband.com/20MB.zip")!, // See https://testfiledownload.com
            //			url: URL(string: "https://picsum.photos/5000")!,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData
        )

        let sema = DispatchSemaphore(value: 0)
        let publisher = URLSession.shared.dataTaskPublisherWithProgress(for: request)

        var results = [URLSession.DataTaskProgress]()

        let _doNotChangeThisName = publisher
            .sink { completion in
                if case let .failure(error) = completion {
                    XCTFail("\(error)")
                }
                print("FINISHED")
                sema.signal()
            } receiveValue: { value in
                results.append(value)

                DispatchQueue.global().async {
                    switch value {
                    case let .progress(task):
                        print("progress:", task.progress.fractionCompleted)
                    case let .result(data, _):
                        print("data downloaded:", data.humanSize())
                    }
                }
            }

        sema.wait()
        _doNotChangeThisName.cancel()

        XCTAssertGreaterThan(results.count, 10)
    }

    func test_progress_usingClient() throws {
        // given
        // See https://fastest.fish/test-files
        let client = NetworkingClient(baseURL: URL(string: "https://sabnzbd.org/tests/internetspeed")!, logger: nil)

        // when
        let publisher: AnyPublisher<NetworkingProgressOrResponse, NetworkingError> = client
            .get("20MB.bin")
            .performWithProgress()

        var progresses = [NetworkingProgress]()

        let sema = DispatchSemaphore(value: 0)

        let _doNotChangeThisName = publisher
            .sink { completion in
                if case let .failure(error) = completion {
                    XCTFail("\(error)")
                }
                print("FINISHED")
                sema.signal()
            } receiveValue: { output in
                switch output {
                case let .progress(progress):
                    print("progress:", progress.fractionCompleted)
                    progresses.append(progress)
                case let .result(response):
                    print("data downloaded:", response.data.humanSize())
                }
            }

        XCTAssertEqual(sema.wait(timeout: .now() + 60), .success)
        _doNotChangeThisName.cancel()

        // then
        XCTAssertGreaterThan(progresses.count, 10, progresses.description)
        XCTAssertEqual(progresses.sorted(), progresses, progresses.description)
    }
}
