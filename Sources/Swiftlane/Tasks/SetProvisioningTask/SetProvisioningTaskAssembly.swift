//

import Foundation
import Provisioning
import SwiftlaneCore
import Xcodebuild

public final class SetProvisioningTaskAssembly {
    public func assemble(config: SetProvisioningTaskConfig, logger: Logging) -> SetProvisioningTask {
        let filesManager = FSManager(
            logger: logger,
            fileManager: FileManager.default
        )

        let shell = ShellExecutor(
            sigIntHandler: SigIntHandler(logger: logger),
            logger: logger,
            xcodeChecker: XcodeChecker(),
            filesManager: filesManager
        )

        let provisionProfileParser = MobileProvisionParser(
            logger: logger,
            shell: shell
        )

        let provisioningProfileService = ProvisioningProfilesService(
            filesManager: filesManager,
            logger: logger,
            provisionProfileParser: provisionProfileParser
        )

        let projectPatcher = XcodeProjectPatcher(
            logger: logger,
            shell: shell,
            plistBuddyService: PlistBuddyService(shell: shell)
        )

        return SetProvisioningTask(
            provisioningProfileService: provisioningProfileService,
            projectPatcher: projectPatcher,
            config: config
        )
    }
}
