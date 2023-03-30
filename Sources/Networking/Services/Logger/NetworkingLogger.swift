//

import Foundation
import SwiftlaneCore

/// Protocol of logger for `NetworkingClient`.
// sourcery:AutoMockable
public protocol NetworkingLoggerProtocol: AnyObject {
    /// Do not set this by hand, set `NetworkingClient.logLevel` instead.
    var logLevel: LoggingLevel { get set }

    func log(client: NetworkingClient, request: NetworkingRequest, urlRequest: URLRequest, uuid: UUID)
    func log(client: NetworkingClient, response: NetworkingResponse, requestUUID: UUID)
    func log(unexpectedBehaviour message: String)
}

/// Default logger implementation for `NetworkingClient` which print somewhat pretty info via `print`.
public final class NetworkingLogger: NetworkingLoggerProtocol {
    public var logLevel: LoggingLevel
    public var logger: Logging

    public init(logLevel: LoggingLevel, logger: Logging) {
        self.logLevel = logLevel
        self.logger = logger
    }

    // swiftformat:disable indent
	public func log(client _: NetworkingClient, request: NetworkingRequest, urlRequest _: URLRequest, uuid: UUID) {
		logger.log(
		    logLevel,
		    """
			=== 🌍 \(uuid) 🌍 ===
			\(request.description)
			===================================================
			""",
		    .blue
		)
	}

	public func log(client _: NetworkingClient, response: NetworkingResponse, requestUUID: UUID) {
		let emoji = response.status.isSuccess ? "💚" : "💥"
		let message =
			"""
			=== \(emoji) \(requestUUID) \(emoji) ===
			\(response.description)
			===================================================
			"""

		if response.status.isSuccess {
			logger.log(logLevel, message, .green)
		} else {
			logger.error(message)
		}
	}

	// swiftformat:enable indent

    public func log(unexpectedBehaviour message: String) {
        logger.log(logLevel, "⚠️ unexpectedBehaviour \(message)")
    }
}
