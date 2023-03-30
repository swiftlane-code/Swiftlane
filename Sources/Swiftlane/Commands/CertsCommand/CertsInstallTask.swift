//

import Foundation

import AppStoreConnectAPI
import Provisioning
import Simulator
import SwiftlaneCore
import Xcodebuild

public final class CertsInstallTask {
    private let logger: Logging
    private let shell: ShellExecuting
    private let installer: CertsInstaller

    private let config: CertsInstallConfig

    public init(
        logger: Logging,
        shell: ShellExecuting,
        installer: CertsInstaller,
        config: CertsInstallConfig
    ) {
        self.logger = logger
        self.shell = shell
        self.installer = installer
        self.config = config
    }

    @discardableResult
    public func run() throws -> [(profile: MobileProvision, installPath: AbsolutePath)] {
        try installer.installCertificatesAndProfiles(config: config)
    }
}
