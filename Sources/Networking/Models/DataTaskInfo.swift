//

import Foundation

public enum DataTaskInfo {
    public typealias ProgressObject = URLSessionDataTask

    case progress(URLSessionDataTask)
    case result(data: Data, response: URLResponse)

    public var progress: ProgressObject? {
        switch self {
        case let .progress(value):
            return value
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
