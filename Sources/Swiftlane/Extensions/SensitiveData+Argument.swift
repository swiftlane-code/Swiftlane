//

import ArgumentParser
import Foundation
import SwiftlaneCore

extension SensitiveData: ExpressibleByArgument where T: ExpressibleByArgument {
    public init?(argument: String) {
        guard let value = T(argument: argument) else {
            return nil
        }
        self.init(value)
    }
}
