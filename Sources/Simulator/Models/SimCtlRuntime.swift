//

import Foundation

/// Simulator runtime info.
public struct SimCtlRuntime: Decodable, Equatable {
    /// E.g. `"com.apple.CoreSimulator.SimRuntime.tvOS-13-5"`.
    public let identifier: String
    /// Name is `platform + " " + version`
    public let name: String
    /// E.g. `"tvOS"`.
    public let platform: String?
    /// E.g. `"13.5"`.
    public let version: String
    /// E.g. `"19K50"`.
    public let buildversion: String
    public let isAvailable: Bool
}
