//

import Foundation

// sourcery: AutoMockable
public protocol XcodebuildCommandProducing {
    func produce() -> String
}

public struct XcodebuildCommandProducer {
    let isUseRosetta: Bool

    public init(isUseRosetta: Bool) {
        self.isUseRosetta = isUseRosetta
    }
}

extension XcodebuildCommandProducer: XcodebuildCommandProducing {
    public func produce() -> String {
        let rosettaInjection = isUseRosetta ? "arch -x86_64" : ""

        return "env NSUnbufferedIO=YES \(rosettaInjection) xcodebuild"
    }
}
