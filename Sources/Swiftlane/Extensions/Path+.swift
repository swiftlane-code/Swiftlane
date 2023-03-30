//

import ArgumentParser
import SwiftlaneCore

extension Path: ExpressibleByArgument {
    public init?(argument: String) {
        try? self.init(argument)
    }
}

extension RelativePath: ExpressibleByArgument {
    public init?(argument: String) {
        try? self.init(argument)
    }
}

extension AbsolutePath: ExpressibleByArgument {
    public init?(argument: String) {
        try? self.init(argument)
    }
}
