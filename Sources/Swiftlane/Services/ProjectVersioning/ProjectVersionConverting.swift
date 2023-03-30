//

import Foundation
import SwiftlaneCore

public protocol ProjectVersionConverting {
    func convertAppVersionToPlistValue(_ version: SemVer) throws -> String
    func convertAppVersionFromPlistValue(_ version: String?) throws -> SemVer
}

public class StraightforwardProjectVersionConverter: Initable, ProjectVersionConverting {
    public required init() {}

    public func convertAppVersionToPlistValue(_ version: SemVer) throws -> String {
        version.string(format: .full)
    }

    public func convertAppVersionFromPlistValue(_ version: String?) throws -> SemVer {
        let unwrapped = try version.unwrap(errorDescription: "Is your project version in Info.plist nil?")
        return try SemVer(parseFrom: unwrapped)
    }
}
