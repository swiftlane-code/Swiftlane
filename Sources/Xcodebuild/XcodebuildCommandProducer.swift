//

import Foundation

// sourcery: AutoMockable
public protocol XcodebuildCommandProducing {
    func produce() -> String
}

public struct XcodebuildCommandProducer {
    let shouldUseRosetta: Bool

    public init(isUseRosetta: Bool) {
        self.shouldUseRosetta = isUseRosetta
    }
}

extension XcodebuildCommandProducer: XcodebuildCommandProducing {
    public func produce() -> String {
        [
            "env NSUnbufferedIO=YES",
            shouldUseRosetta ? "arch -x86_64" : nil,
            "xcodebuild"
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }
}
