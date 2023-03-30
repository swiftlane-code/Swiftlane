//

import Foundation

public struct XCCOVCoverageReport: Decodable, Equatable {
    /// Total coverage percent
    public let lineCoverage: Double
    public let targets: [XCCOVTargetCoverage]
}

public struct XCCOVTargetCoverage: Decodable, Equatable {
    /// Product name of the target
    /// e.g. `SMDeeplinks.framework`
    public let name: String
    public let executableLines: Int
    public let coveredLines: Int
    /// Coverage of target from 0 to 1
    public let lineCoverage: Double
    public let files: [XCCOVFileCoverage]

    public var realTargetName: String {
        String(name.split(separator: ".").first!)
    }
}

public struct XCCOVFileCoverage: Decodable, Equatable {
    /// e.g. `AppDelegate.swift`
    public let name: String
    /// Absolute path to file
    public let path: String
    public let executableLines: Int
    public let coveredLines: Int
    /// Coverage of file from 0 to 1
    public let lineCoverage: Double
}
