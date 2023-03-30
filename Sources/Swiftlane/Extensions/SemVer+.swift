//

import ArgumentParser
import Foundation
import SwiftlaneCore

extension SemVer: ExpressibleByArgument {
    /// ExpressibleByArgument
    public init?(argument: String) {
        try? self.init(parseFrom: argument)
    }
}
