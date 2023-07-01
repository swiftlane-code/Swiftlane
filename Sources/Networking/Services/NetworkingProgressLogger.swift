//

import Combine
import Foundation
import SwiftlaneCore

public protocol NetworkingProgressLogging {
    func performLoggingProgress<Result>(
        description: String,
        publisher: AnyPublisher<ProgressOrResult<NetworkingProgress, Result>, NetworkingError>,
        timeout: TimeInterval
    ) throws -> Result

    func performLoggingDoubleProgress<Result, Failure>(
        description: String,
        publisher: AnyPublisher<ProgressOrResult<Double, Result>, Failure>,
        timeout: TimeInterval
    ) throws -> Result
}

public class NetworkingProgressLogger: NetworkingProgressLogging {
    private let progressLogger: ProgressLogging

    public init(progressLogger: ProgressLogging) {
        self.progressLogger = progressLogger
    }

    public func performLoggingProgress<Result>(
        description: String,
        publisher: AnyPublisher<ProgressOrResult<NetworkingProgress, Result>, NetworkingError>,
        timeout: TimeInterval
    ) throws -> Result {
        let doubleProgress: AnyPublisher<ProgressOrResult<Double, Result>, NetworkingError> = publisher
            .map {
                switch $0 {
                case let .progress(progress):
                    return .progress(progress.fractionCompleted)
                case let .result(result):
                    return .result(result)
                }
            }
            .eraseToAnyPublisher()

        return try performLoggingDoubleProgress(
            description: description,
            publisher: doubleProgress,
            timeout: timeout
        )
    }

    public func performLoggingDoubleProgress<Result, Failure>(
        description: String,
        publisher: AnyPublisher<ProgressOrResult<Double, Result>, Failure>,
        timeout: TimeInterval
    ) throws -> Result {
        print(description + " starting...", terminator: "")

        let result = try publisher
            .handleEvents(receiveOutput: { [progressLogger] progressOrResult in
                let fraction: Double
                switch progressOrResult {
                case let .progress(progress):
                    fraction = progress
                case .result:
                    fraction = 1
                }
                progressLogger.logFancy(
                    progress: fraction,
                    description: description
                )
            })
            .compactMap(\.result)
            .await(timeout: timeout + 1)

        return result
    }
}
