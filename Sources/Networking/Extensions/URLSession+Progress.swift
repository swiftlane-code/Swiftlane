//

import Combine
import Foundation

public extension URLSession {
    enum DataTaskProgress {
        case progress(task: URLSessionDataTask)
        case result(data: Data, response: URLResponse)

        public var progressTask: URLSessionDataTask? {
            switch self {
            case let .progress(task):
                return task
            case .result:
                return nil
            }
        }

        public var result: (data: Data, response: URLResponse)? {
            switch self {
            case .progress:
                return nil
            case let .result(data, response):
                return (data, response)
            }
        }
    }

    /// Keep in mind that each subscription to this publisher triggers a new request.
    ///	Use `Publisher.share()` if you want to share multiple subscriptions.
    /// This publisher supports retries via `Publisher.retry()`.
    ///	In order for retry to work `.retry()` should be called before `.share()`.
    ///
    ///	Usage example with retry and share:
    ///
    ///
    ///		let session = URLSession.shared
    ///		let publisher = session.dataTaskPublisherWithProgress(for: urlRequest)
    ///			.retry(4, delay: .seconds(10))
    ///			.share()
    ///
    ///		publisher
    ///			.compactMap(\.progressTask)
    ///			.map(\.progress.fractionCompleted)
    ///			.print("progress > ")
    ///			.sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    ///			.store(in: &subs)
    ///
    ///		let response = try publisher.compactMap(\.result)
    ///			.print("response > ")
    ///			.await(timeout: 1000)
    ///
    ///		print(response)
    ///
    ///
    /// - Parameter request: request to perform.
    /// - Returns:
    ///	 * `progress` emits `URLSessionDataTask` object every time
    ///	 	when `URLSessionDataTask.progress.fractionCompleted` value changes.
    ///	 * `response` emits single value after request is finished.
    func dataTaskPublisherWithProgress(
        for request: URLRequest
    ) -> AnyPublisher<DataTaskProgress, Error> {
        Deferred { [self] () -> AnyPublisher<DataTaskProgress, Error> in
            let completion = PassthroughSubject<DataTaskProgress, Error>()

            let task = self.dataTask(with: request) { data, response, error in
                if let data = data, let response = response {
                    completion.send(.result(data: data, response: response))
                    completion.send(completion: .finished)
                } else if let error = error {
                    completion.send(completion: .failure(error))
                } else {
                    print("Fatal error at \(#file):\(#line)")
                    fatalError("This should be unreachable, something is clearly wrong.")
                }
            }

            let progress: AnyPublisher<DataTaskProgress, Error> = task
                .publisher(for: \.progress.fractionCompleted)
                .map { _ in .progress(task: task) }
                .setFailureType(to: Error.self)
                .prefix(untilOutputFrom: completion)
                .eraseToAnyPublisher()

            return completion
                .merge(with: progress)
                .handleEvents(receiveCancel: {
                    task.cancel()
                }, receiveRequest: { _ in
                    task.resume()
                })
                .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}
