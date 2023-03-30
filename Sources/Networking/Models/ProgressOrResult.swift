//

import Combine
import Foundation

public typealias NetworkingProgressOrResponse = ProgressOrResult<NetworkingProgress, NetworkingResponse>

public enum ProgressOrResult<Progress, Result> {
    case progress(Progress)
    case result(Result)

    var progress: Progress? {
        switch self {
        case let .progress(task):
            return task
        case .result:
            return nil
        }
    }

    var result: Result? {
        switch self {
        case .progress:
            return nil
        case let .result(result):
            return result
        }
    }
}
