//

import Foundation
import Git
import Provisioning
import Simulator
import SwiftlaneCore
import Yams

public final class CertsInstallTaskAssembly {
    public func assemble(config: CertsInstallConfig, logger: Logging) throws -> CertsInstallTask {
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

        let git = Git(
            shell: shell,
            filesManager: filesManager,
            diffParser: GitDiffParser(logger: logger)
        )

        let openssl = OpenSSLService(
            shell: shell,
            filesManager: filesManager
        )

        let provisionProfileParser = MobileProvisionParser(
            logger: logger,
            shell: shell
        )

        let security = MacOSSecurity(shell: shell)

        let provisioningProfileService = ProvisioningProfilesService(
            filesManager: filesManager,
            logger: logger,
            provisionProfileParser: provisionProfileParser
        )

        let certsRepo = CertsRepository(
            git: git,
            openssl: openssl,
            filesManager: filesManager,
            provisioningProfileService: provisioningProfileService,
            provisionProfileParser: provisionProfileParser,
            security: security,
            logger: logger,
            config: CertsRepository.Config(
                gitAuthorName: nil,
                gitAuthorEmail: nil
            )
        )

        let remoteCertInstaller = RemoteCertificateInstaller(
            logger: logger,
            shell: shell,
            filesManager: filesManager,
            security: security,
            urlSession: URLSession.shared
        )

        let task = CertsInstallTask(
            logger: logger,
            shell: shell,
            installer: CertsInstaller(
                logger: logger,
                repo: certsRepo,
                atomicInstaller: CertsAtomicInstaller(
                    logger: logger,
                    filesManager: filesManager,
                    openssl: openssl,
                    security: security,
                    provisioningProfileService: provisioningProfileService
                ),
                filesManager: filesManager,
                remoteCertInstaller: remoteCertInstaller
            ),
            config: config
        )

        return task
    }
}
