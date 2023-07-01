//

import Foundation
import SwiftlaneCore

public struct GuardianAfterBuildCommandConfig: Decodable {
    public let changesCoverageLimitCheckerConfig: ChangesCoverageLimitChecker.DecodableConfig
    public let targetsCoverageLimitCheckerConfig: TargetsCoverageLimitChecker.DecodableConfig
    public let buildWarningCheckerConfig: BuildWarningsChecker.DecodableConfig

    public init(
        changesCoverageLimitCheckerConfig: ChangesCoverageLimitChecker.DecodableConfig,
        targetsCoverageLimitCheckerConfig: TargetsCoverageLimitChecker.DecodableConfig,
        buildWarningCheckerConfig: BuildWarningsChecker.DecodableConfig
    ) {
        self.changesCoverageLimitCheckerConfig = changesCoverageLimitCheckerConfig
        self.targetsCoverageLimitCheckerConfig = targetsCoverageLimitCheckerConfig
        self.buildWarningCheckerConfig = buildWarningCheckerConfig
    }
}
