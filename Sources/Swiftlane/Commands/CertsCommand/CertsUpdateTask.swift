//

import AppStoreConnectAPI
import Foundation
import Provisioning
import Simulator
import SwiftlaneCore
import Xcodebuild

public final class CertsUpdateTask {
    private let logger: Logging
    private let shell: ShellExecuting
    private let certsService: CertsUpdating

    private let config: CertsUpdateConfig

    public init(
        logger: Logging,
        shell: ShellExecuting,
        certsService: CertsUpdating,
        config: CertsUpdateConfig
    ) {
        self.logger = logger
        self.shell = shell
        self.certsService = certsService
        self.config = config
    }

    public func run() throws {
        try certsService.updateCertificatesAndProfiles(
            updateConfig: config
        )
    }
}
