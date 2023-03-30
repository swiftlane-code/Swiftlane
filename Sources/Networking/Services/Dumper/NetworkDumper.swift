//

import Foundation
import SwiftlaneCore

/// Allows to dump requests and responses. (Can be injected into ``NetworkingClient``).
/// Usefull for API debugging.
/// Note: It doesn't dump headers.
public class NetworkingDumper {
    /// Root directory where dump will be written to.
    public let dumpsRootDir: AbsolutePath

    private let filesManager: FSManaging
    private let serializer: JSONSerializer

    /// - Parameter dumpsRootDir: Root directory where dump will be written to.
    public init(
        dumpsRootDir: AbsolutePath,
        filesManager: FSManaging,
        serializer: JSONSerializer? = nil
    ) throws {
        self.dumpsRootDir = dumpsRootDir
        self.filesManager = filesManager
        self.serializer = serializer ?? JSONSerializer(encoder: {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return encoder
        }())

        try filesManager.mkdir(dumpsRootDir)
    }

    private func dumpFilePath(for route: String, uuid: UUID) throws -> AbsolutePath {
        var trimmedRoute = route
        while trimmedRoute.hasSuffix("/") {
            trimmedRoute = String(trimmedRoute.dropLast(1))
        }
        return try dumpsRootDir
            .appending(path: route)
            .appending(path: uuid.uuidString + ".json")
    }
}

extension NetworkingDumper: NetworkingDumperProtocol {
    public func dump(response: NetworkingResponse, requestUUID: UUID) {
        do {
            let dumpEntry = DumpEntry(
                response: response,
                requestUUID: requestUUID
            )
            let data = try serializer.serialize(dumpEntry)
            try filesManager.write(dumpFilePath(for: response.request.route, uuid: requestUUID), data: data)
        } catch {
            assertionFailure(
                "NetworkingDumper unable to encode request with uuid: \(requestUUID), error: \(String(reflecting: error))"
            )
        }
    }
}
