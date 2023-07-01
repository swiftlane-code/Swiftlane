//

import Foundation
import SwiftlaneCore

public protocol RemoteCertificateInstalling {
    func installCertificate(
        from url: URL,
        downloadTimeout: TimeInterval,
        keychainName: String,
        installTimeout: TimeInterval
    ) throws
}

public class RemoteCertificateInstaller: RemoteCertificateInstalling {
    private let logger: Logging
    private let shell: ShellExecuting
    private let filesManager: FSManaging
    private let security: MacOSSecurityProtocol
    private let urlSession: URLSession

    public init(
        logger: Logging,
        shell: ShellExecuting,
        filesManager: FSManaging,
        security: MacOSSecurityProtocol,
        urlSession: URLSession
    ) {
        self.logger = logger
        self.shell = shell
        self.filesManager = filesManager
        self.security = security
        self.urlSession = urlSession
    }

    public func installCertificate(
        from url: URL,
        downloadTimeout: TimeInterval,
        keychainName: String,
        installTimeout: TimeInterval
    ) throws {
        logger.important("Downloading \(url.absoluteString.quoted)...")

        let (data, _) = try urlSession.dataTaskPublisher(for: url).await(timeout: downloadTimeout)

        let tmpPath = try AbsolutePath(
            shell.run(
                "mktemp /tmp/cert.cer_XXXXXXX",
                log: .commandOnly,
                silentStdErrMessages: true
            ).stdoutText.unwrap()
                .trimmingCharacters(in: .whitespacesAndNewlines)
        )

        defer {
            try? filesManager.delete(tmpPath)
        }

        try filesManager.write(tmpPath, data: data)

        let keychainPath = try security.getKeychainPath(keychainName: keychainName)

        let installed = try security.importItem(
            item: tmpPath,
            keychainPath: keychainPath,
            trustedBinaries: [],
            timeout: installTimeout
        )

        if installed {
            logger.success("Certificate from \(url.absoluteString.quoted) was successfully imported into \(keychainPath).")
        } else {
            logger.success("Certificate from \(url.absoluteString.quoted) already exists in \(keychainPath).")
        }
    }
}
