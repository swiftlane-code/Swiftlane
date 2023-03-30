//

import Foundation

/// The response class representation of status codes, these get grouped by their first digit.
public enum ResponseType {
    /// - informational: This class of status code indicates a provisional response, consisting only of the Status-Line and optional headers, and is terminated by an empty line.
    case informational

    /// - success: This class of status codes indicates the action requested by the client was received, understood, accepted, and processed successfully.
    case success

    /// - redirection: This class of status code indicates the client must take additional action to complete the request.
    case redirection

    /// - clientError: This class of status code is intended for situations in which the client seems to have erred.
    case clientError

    /// - serverError: This class of status code indicates the server failed to fulfill an apparently valid request.
    case serverError

    /// - undefined: The class of the status code cannot be resolved.
    case undefined
}
