//

import Foundation
import Provisioning
import SwiftlaneCore
import Xcodebuild

public struct SetProvisioningTaskConfig {
    public let xcodeprojPath: AbsolutePath
    public let schemeName: String
    public let buildConfigurationName: String
    public let provisionProfileName: String
}

public final class SetProvisioningTask {
    private let provisioningProfileService: ProvisioningProfilesServicing
    private let projectPatcher: XcodeProjectPatching

    private let config: SetProvisioningTaskConfig

    public init(
        provisioningProfileService: ProvisioningProfilesServicing,
        projectPatcher: XcodeProjectPatching,
        config: SetProvisioningTaskConfig
    ) {
        self.provisioningProfileService = provisioningProfileService
        self.projectPatcher = projectPatcher
        self.config = config
    }

    public func run() throws {
        let (profile, _) = try provisioningProfileService
            .findProvisioningProfile(named: config.provisionProfileName)

        try projectPatcher.setProvisionProfile(
            xcodeprojPath: config.xcodeprojPath,
            schemeName: config.schemeName,
            configurationName: config.buildConfigurationName,
            profileUUID: profile.UUID,
            profileName: profile.Name
        )
    }
}
