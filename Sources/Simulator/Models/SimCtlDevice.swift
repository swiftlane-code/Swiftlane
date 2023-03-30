//

import Foundation

public struct SimCtlDevice: Decodable, Equatable {
    public let dataPath: String
    public let logPath: String
    public let udid: String
    public let isAvailable: Bool
    public let deviceTypeIdentifier: String?
    public let state: State
    public let name: String

    public enum State: String, Decodable {
        case unknown = "<unknown>"
        case creating = "Creating"
        case booting = "Booting"
        case booted = "Booted"
        case shuttingDown = "ShuttingDown"
        case shutdown = "Shutdown"

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            self = State(rawValue: string) ?? .unknown
        }
    }
}
