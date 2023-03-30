//

import Foundation
import Guardian

public extension MergeRequestReportFactory {
    convenience init() {
        self.init(captionProvider: MergeRequestReportCaptionProvider(
            ciToolName: "🦾🤖 Swiftlane (\(UTILL_VERSION))"
        ))
    }
}
