//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol MobileProvisionParsing {
    func parse(provisionPath: AbsolutePath) throws -> MobileProvision
}

public final class MobileProvisionParser {
    private let logger: Logging
    private let shell: ShellExecuting

    public init(
        logger: Logging,
        shell: ShellExecuting
    ) {
        self.logger = logger
        self.shell = shell
    }
}

extension MobileProvisionParser: MobileProvisionParsing {
    /// Parses a `.mobileprovision` (iOS) or `.provisionprofile` (macOS) file.
    /// - Parameter provisionPath: path to provisioning profile file.
    ///   Asserted that `provisionPath` has `.mobileprovision` or `.provisionprofile` suffix.
    public func parse(provisionPath: AbsolutePath) throws -> MobileProvision {
        let validExtensions = [".mobileprovision", ".provisionprofile"]

        if !validExtensions.contains(where: { provisionPath.hasSuffix($0) }) {
            let msg = "\(provisionPath.string.quoted) is not a valid provisioning profile file. Expected extensions: \(validExtensions.joined(separator: ", "))"
            logger.error(msg)
            assertionFailure(msg)
        }

        let deobfuscateCommand = "security cms -D -i " + provisionPath.string.quoted
        let plistText = try shell.run(
            deobfuscateCommand,
            log: .silent,
            maskSubstringsInLog: [],
            silentStdErrMessages: true
        ).stdoutText.unwrap(
            errorDescription: "stdout of \(deobfuscateCommand.quoted) is nil."
        )

        let plistData = try plistText.data(using: .utf8).unwrap(
            errorDescription: "Unable to get utf8 data from plist text: \(plistText)."
        )

        let decoder = PropertyListDecoder()
        let profile = try decoder.decode(MobileProvision.self, from: plistData)
        return profile
    }
}
