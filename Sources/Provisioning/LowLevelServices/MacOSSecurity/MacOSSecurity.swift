//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol MacOSSecurityProtocol {
    /// Delete certificate and it's private key from keychain.
    /// - Parameters:
    ///   - certificateFingerprint: certificate's SHA-256 (or SHA-1) hash value.
    ///   - keychainPath: path to keychain.
    ///   - timeout: timeout.
    func deleteCertificateAndPrivateKey(
        certificateFingerprint: String,
        deleteTrustSettings: Bool,
        keychainPath: AbsolutePath?,
        timeout: TimeInterval
    ) throws

    /// Import item into keychain.
    /// - Parameters:
    ///   - item: path to file.
    ///   - keychainPath: path to keychain.
    ///   - trustedBinaries: application which may access the imported key.
    ///   - timeout: timeout.
    /// - Returns: `true` if the item was installed. `false` if the item already exists in the keychain.
    func importItem(
        item: AbsolutePath,
        keychainPath: AbsolutePath?,
        trustedBinaries: [String],
        timeout: TimeInterval
    ) throws -> Bool

    /// Allows Apple apps to sign things using keys from keychain.
    ///
    /// See: https://stackoverflow.com/questions/39868578/security-codesign-in-sierra-keychain-ignores-access-control-settings-and-ui-p
    func allowSigningUsingKeysFromKeychain(
        _ keychainPath: AbsolutePath?,
        password: String
    ) throws

    /// Returns paths to all existing keychains.
    func listKeychains() throws -> [AbsolutePath]

    func unlockKeychain(_ keychainPath: AbsolutePath?, password: String) throws

    func lockKeychain(_ keychainPath: AbsolutePath?) throws

    func getKeychainPath(keychainName: String) throws -> AbsolutePath

    func validCodesigningIdentities(
        _ keychainPath: AbsolutePath?
    ) throws -> [CodesigningIdentity]
}

/// Wrapper around `security` MacOS CLI tool.
///
/// Hint: `$ security help`.
public final class MacOSSecurity: MacOSSecurityProtocol {
    private let shell: ShellExecuting

    public init(
        shell: ShellExecuting
    ) {
        self.shell = shell
    }

    /// Delete certificate and it's private key from keychain.
    /// - Parameters:
    ///   - certificateFingerprint: certificate's SHA-256 (or SHA-1) hash value.
    ///   	It should NOT contain any separating characters like `:`.
    ///   - keychainPath: path to keychain.
    ///   - timeout: timeout.
    public func deleteCertificateAndPrivateKey(
        certificateFingerprint: String,
        deleteTrustSettings: Bool,
        keychainPath: AbsolutePath?,
        timeout _: TimeInterval
    ) throws {
        try shell.run(
            [
                "security delete-identity",
                "-Z '\(certificateFingerprint)'",
                deleteTrustSettings ? "-t" : nil,
                keychainPath?.string.quoted,
            ].compactMap { $0 }, log: .commandAndOutput(outputLogLevel: .important)
        )
    }

    /// Import item into keychain.
    /// - Parameters:
    ///   - item: path to file.
    ///   - keychainPath: path to keychain.
    ///   - trustedBinaries: application which may access the imported key.
    ///   - timeout: timeout.
    /// - Returns: `true` if the item was installed. `false` if the item already exists in the keychain.
    public func importItem(
        item: AbsolutePath,
        keychainPath: AbsolutePath?,
        trustedBinaries: [String],
        timeout: TimeInterval
    ) throws -> Bool {
        func alreadyExists(_ output: ShellOutput) -> Bool {
            output.stderrText?.contains("The specified item already exists in the keychain") == true
        }
        let output = try shell.run(
            [
                // Do NOT change order of arguments!
                "security import",
                item.string.quoted,
                keychainPath.map { "-k " + $0.string.quoted },
            ].compactMap { $0 } + trustedBinaries.map { "-T '\($0)'" },
            log: .commandAndOutput(outputLogLevel: .verbose),
            executionTimeout: timeout, // Prevents being stuck on "Enter password" system UI popup.
            shouldIgnoreNonZeroExitCode: { output, _ in
                alreadyExists(output)
            },
            silentStdErrMessages: true
        )
        return !alreadyExists(output)
    }

    public func listKeychains() throws -> [AbsolutePath] {
        let command = "security list-keychains"
        let commandResult = try shell.run(command, log: .silent, silentStdErrMessages: true)

        let result = try commandResult.stdoutText.unwrap(errorDescription: "nil output of \(command.quoted)")
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { $0.trimmingCharacters(in: .init(charactersIn: "\"")) }
            .map { try AbsolutePath($0) }

        return result
    }

    public func getKeychainPath(keychainName: String) throws -> AbsolutePath {
        let allKeychains = try listKeychains()
        return try allKeychains
            .first { $0.lastComponent.deletingExtension.string == keychainName }
            .unwrap(errorDescription: "Keychain with name \(keychainName.quoted) not found. Existing: \(allKeychains)")
    }

    public func unlockKeychain(_ keychainPath: AbsolutePath?, password: String) throws {
        try shell.run(
            [
                "security unlock-keychain",
                "-p '\(password)'",
                keychainPath?.string.quoted,
            ].compactMap { $0 },
            log: .commandAndOutput(outputLogLevel: .verbose),
            maskSubstringsInLog: [password],
            executionTimeout: 10 // Prevents being stuck on "Enter password".
        )
    }

    public func lockKeychain(_ keychainPath: AbsolutePath?) throws {
        try shell.run([
            "security lock-keychain",
            keychainPath?.string,
        ].compactMap { $0 }, log: .commandAndOutput(outputLogLevel: .verbose))
    }

    /// Allows Apple apps to sign things using keys from keychain.
    ///
    /// See: https://stackoverflow.com/questions/39868578/security-codesign-in-sierra-keychain-ignores-access-control-settings-and-ui-p
    public func allowSigningUsingKeysFromKeychain(
        _ keychainPath: AbsolutePath?,
        password: String
    ) throws {
        try shell.run(
            [
                "security set-key-partition-list",
                "-S apple-tool:,apple:",
                "-s",
                "-k '\(password)'",
                keychainPath?.string.quoted,
                "1> /dev/null", // Proccessing tons of meaningless stdout text takes a lot of time so we suppress it.
            ].compactMap { $0 },
            log: .commandOnly,
            maskSubstringsInLog: [password]
        )
    }

    public func validCodesigningIdentities(
        _ keychainPath: AbsolutePath?
    ) throws -> [CodesigningIdentity] {
        let output = try shell.run(
            [
                "security find-identity",
                "-p codesigning",
                "-v",
                keychainPath?.string.quoted,
            ].compactMap { $0 },
            log: .commandAndOutput(outputLogLevel: .verbose),
            silentStdErrMessages: true
        ).stdoutText.unwrap(errorDescription: "stdout of 'security find-identity' is nil.")

        let regex = try NSRegularExpression(
            pattern: #"^\s*\d+\) (\w+) "(.+): (.+) \((.+)\)"$"#,
            options: .anchorsMatchLines
        )

        return regex.matchesGroups(in: output).map {
            CodesigningIdentity(
                fingerprint: String($0[1]),
                type: String($0[2]),
                name: String($0[3]),
                teamID: String($0[4])
            )
        }
    }
}
