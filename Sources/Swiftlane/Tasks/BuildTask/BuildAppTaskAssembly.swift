//

import Foundation
import SwiftlaneCore
import Xcodebuild

public final class BuildAppTaskAssembly {
    public func assemble(
        paths _: PathsFactoring,
        builderConfig: Builder.Config,
        buildForTesting: Bool,
        buildDestination: BuildDestination,
        isUseRosetta: Bool,
        logger: Logging

    ) -> BuildAppTask {
        let filesManager = FSManager(
            logger: logger,
            fileManager: FileManager.default
        )

        let logPathFactory = LogPathFactory(filesManager: filesManager)

        let shell = ShellExecutor(
            sigIntHandler: SigIntHandler(logger: logger),
            logger: logger,
            xcodeChecker: XcodeChecker(),
            filesManager: filesManager
        )

        let xcodebuildCommand = XcodebuildCommandProducer(isUseRosetta: isUseRosetta)

        let builder = Builder(
            filesManager: filesManager,
            logPathFactory: logPathFactory,
            shell: shell,
            logger: logger,
            timeMeasurer: TimeMeasurer(logger: logger),
            xcodebuildCommand: xcodebuildCommand,
            config: builderConfig
        )

        let buildTask = BuildAppTask(
            builder: builder,
            buildForTesting: buildForTesting,
            destination: buildDestination
        )

        return buildTask
    }
}
