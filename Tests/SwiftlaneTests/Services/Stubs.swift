//

import Foundation
import SwiftlaneCore
import SwiftlaneUnitTestTools

@testable import Swiftlane

extension ParsedExpiringToDoModel {
    static func random(
        file: RelativePath = .random(),
        line: UInt = .random(in: 0 ... 10_000_000),
        fullMatch: String = .random(),
        author: String? = .random(),
        dateString: String = .random()
    ) -> Self {
        ParsedExpiringToDoModel(
            file: file,
            line: line,
            fullMatch: fullMatch,
            author: author,
            dateString: dateString
        )
    }
}
