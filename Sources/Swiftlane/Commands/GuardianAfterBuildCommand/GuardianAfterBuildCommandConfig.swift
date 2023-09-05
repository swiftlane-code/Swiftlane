//

import Foundation
import SwiftlaneCore

public struct GuardianAfterBuildCommandConfig: Decodable {
    public let changesCoverageLimitCheckerConfig: ChangesCoverageLimitChecker.DecodableConfig?
    public let targetsCoverageLimitCheckerConfig: TargetsCoverageLimitChecker.DecodableConfig
    public let buildWarningCheckerConfig: BuildWarningsChecker.DecodableConfig
    public let slatherReportFilePath: Path

    public init(
        changesCoverageLimitCheckerConfig: ChangesCoverageLimitChecker.DecodableConfig?,
        targetsCoverageLimitCheckerConfig: TargetsCoverageLimitChecker.DecodableConfig,
        buildWarningCheckerConfig: BuildWarningsChecker.DecodableConfig,
        slatherReportFilePath: Path
    ) {
        self.changesCoverageLimitCheckerConfig = changesCoverageLimitCheckerConfig
        self.targetsCoverageLimitCheckerConfig = targetsCoverageLimitCheckerConfig
        self.buildWarningCheckerConfig = buildWarningCheckerConfig
        self.slatherReportFilePath = slatherReportFilePath
    }
}
