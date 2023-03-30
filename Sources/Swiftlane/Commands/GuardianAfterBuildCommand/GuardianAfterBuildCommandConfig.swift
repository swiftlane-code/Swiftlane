//

import Foundation
import SwiftlaneCore

public struct GuardianAfterBuildCommandConfig: Decodable {
    public let changesCoverageLimitCheckerConfig: ChangesCoverageLimitChecker.DecodableConfig
    public let targetsCoverageLimitCheckerConfig: TargetsCoverageLimitChecker.DecodableConfig
    public let buildWarningCheckerConfig: BuildWarningsChecker.DecodableConfig
}
