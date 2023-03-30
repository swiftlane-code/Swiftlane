//

import Foundation
import Provisioning
import Simulator
import SwiftlaneCore
import Xcodebuild
import Yams

public final class ArchiveAndExportIPATaskAssembly {
    public func assemble(taskConfig: ArchiveAndExportIPATaskConfig, logger: Logging) throws -> ArchiveAndExportIPATask {
        let sigIntHandler = SigIntHandler(logger: logger)
        let xcodeChecker = XcodeChecker()

        let filesManager = FSManager(
            logger: logger,
            fileManager: FileManager.default
        )

        let shell = ShellExecutor(
            sigIntHandler: sigIntHandler,
            logger: logger,
            xcodeChecker: xcodeChecker,
            filesManager: filesManager
        )

        let runtimesMiner = RuntimesMiner(shell: shell)
        let simulatorProvider = SimulatorProvider(
            runtimesMiner: runtimesMiner,
            shell: shell,
            logger: logger
        )

        let timeMeasurer = TimeMeasurer(logger: logger)

        let xcodeBuildCommandProducer = XcodebuildCommandProducer(isUseRosetta: taskConfig.isUseRosetta)

        let archiveProcessor = XCArchiveExporter(
            logger: logger,
            shell: shell,
            filesManager: filesManager,
            timeMeasurer: timeMeasurer,
            xcodebuildCommand: xcodeBuildCommandProducer
        )

        let dsymsExtractor = XCArchiveDSYMsExtractor(
            logger: logger,
            shell: shell,
            filesManager: filesManager,
            timeMeasurer: timeMeasurer
        )

        let provisioningProfilesService = ProvisioningProfilesService(
            filesManager: filesManager,
            logger: logger,
            provisionProfileParser: MobileProvisionParser(logger: logger, shell: shell)
        )

        let task = ArchiveAndExportIPATask(
            simulatorProvider: simulatorProvider,
            logger: logger,
            shell: shell,
            archiveProcessor: archiveProcessor,
            filesManager: filesManager,
            xcodeProjectPatcher: XcodeProjectPatcher(
                logger: logger,
                shell: shell,
                plistBuddyService: PlistBuddyService(shell: shell)
            ),
            dsymsExtractor: dsymsExtractor,
            provisioningProfilesService: provisioningProfilesService,
            config: taskConfig
        )

        return task
    }
}
