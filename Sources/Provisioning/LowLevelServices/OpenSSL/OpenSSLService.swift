//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol OpenSSLServicing {
    /// Decrypt a file.
    func decrypt(
        inFile: AbsolutePath,
        outFile: AbsolutePath,
        cipher: OpenSSLCipherCommand,
        password: String,
        base64: Bool,
        msgDigest: OpenSSLMsgDigest?
    ) throws

    /// Encrypt a file.
    func encrypt(
        inFile: AbsolutePath,
        outFile: AbsolutePath,
        cipher: OpenSSLCipherCommand,
        password: String,
        base64: Bool,
        msgDigest: OpenSSLMsgDigest?
    ) throws

    /// Returns fingerprint of a certificate file.
    func x509Fingerprint(
        inFile: AbsolutePath,
        format: OpenSSLCertificateFormat?,
        msgDigest: OpenSSLMsgDigest
    ) throws -> String

    /// Create a certificate signing request.
    func createCSR(
        commonName: String,
        privateKey: String,
        digest: OpenSSLMsgDigest
    ) throws -> String
}

/// Provides API to use MacOS's `/usr/bin/openssl`.
public final class OpenSSLService: OpenSSLServicing {
    public enum Errors: Error, CustomDebugStringConvertible {
        case badDecrypt
        case badFingerprintParsed(fingerprint: String)
        case badCSRParsed(stdout: String, stderr: String)

        public var debugDescription: String {
            switch self {
            case .badDecrypt:
                return "Decryption failed. It looks like the provided password is invalid."
            case let .badFingerprintParsed(fingerprint):
                return "Parsed fingerprint \(fingerprint) looks like it is invalid."
            case let .badCSRParsed(stdout, stderr):
                return "Unexpected CSR output. stdout: \(stdout). stderr: \(stderr)."
            }
        }
    }

    private let shell: ShellExecuting
    private let filesManager: FSManaging

    public init(
        shell: ShellExecuting,
        filesManager: FSManaging
    ) {
        self.shell = shell
        self.filesManager = filesManager
    }

    public func encrypt(
        inFile: AbsolutePath,
        outFile: AbsolutePath,
        cipher: OpenSSLCipherCommand,
        password: String,
        base64: Bool,
        msgDigest: OpenSSLMsgDigest?
    ) throws {
        let encryptInPlace = inFile == outFile

        let encryptedFile = encryptInPlace
            ? outFile.appending(suffix: ".encrypted")
            : outFile

        do {
            try shell.run(
                [
                    "openssl \(cipher.rawValue)",
                    "-k '\(password)'",
                    "-in '\(inFile)'",
                    "-out '\(encryptedFile)'",
                    base64 ? "-base64" : nil,
                    msgDigest.map { "-md \($0.rawValue)" },
                    "-e",
                ].compactMap { $0 },
                log: .commandAndOutput(outputLogLevel: .debug),
                maskSubstringsInLog: [password]
            )
        } catch let error as ShError {
            if error.stderrText?.starts(with: "bad decrypt") == true {
                throw Errors.badDecrypt
            }
            throw error
        }

        if encryptInPlace {
            try filesManager.delete(inFile)
            try filesManager.move(encryptedFile, newPath: outFile)
        }
    }

    public func decrypt(
        inFile: AbsolutePath,
        outFile: AbsolutePath,
        cipher: OpenSSLCipherCommand,
        password: String,
        base64: Bool,
        msgDigest: OpenSSLMsgDigest?
    ) throws {
        let decryptInPlace = inFile == outFile

        let decryptedFile = decryptInPlace
            ? outFile.appending(suffix: ".decrypted")
            : outFile

        do {
            try shell.run(
                [
                    "openssl \(cipher.rawValue)",
                    "-k '\(password)'",
                    "-in '\(inFile)'",
                    "-out '\(decryptedFile)'",
                    base64 ? "-base64" : nil,
                    msgDigest != nil ? "-md \(msgDigest!.rawValue)" : nil,
                    "-d",
                ].compactMap { $0 },
                log: .commandAndOutput(outputLogLevel: .debug),
                maskSubstringsInLog: [password]
            )
        } catch let error as ShError {
            if error.stderrText?.starts(with: "bad decrypt") == true {
                throw Errors.badDecrypt
            }
            throw error
        }

        if decryptInPlace {
            try filesManager.delete(inFile)
            try filesManager.move(decryptedFile, newPath: outFile)
        }
    }

    /// Note: It will figure out the format by itself, just pass nil.
    public func x509Fingerprint(
        inFile: AbsolutePath,
        format: OpenSSLCertificateFormat? = nil,
        msgDigest: OpenSSLMsgDigest
    ) throws -> String {
        let stdout = try shell.run(
            [
                "openssl x509",
                format.map { "-inform '\($0)'" },
                "-in '\(inFile)'",
                OpenSSLX509Options.noout,
                OpenSSLX509Options.fingerprint,
                msgDigest.asCliOption,
            ].compactMap { $0 },
            log: .commandAndOutput(outputLogLevel: .verbose),
            silentStdErrMessages: true
        ).stdoutText
            .unwrap(errorDescription: "stdout is nil.")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let fingerprint = try stdout.split(separator: "=")[safe: 1]
            .map(String.init)
            .unwrap(
                errorDescription: "Unexpected openssl output: \(stdout)"
            )

        guard
            fingerprint.contains(":"),
            !fingerprint.contains(where: { [" ", "\n"].contains($0) })
        else {
            throw Errors.badFingerprintParsed(fingerprint: fingerprint)
        }

        return fingerprint
    }

    public func createCSR(
        commonName: String,
        privateKey: String,
        digest: OpenSSLMsgDigest
    ) throws -> String {
        // openssl req -new -sha256 -key <(echo "$PK") -subj "/CN=Swiftlane CSR test" -out example.csr
        let output = try shell.run(
            [
                "openssl req -new",
                digest.asCliOption,
                "-key <(echo \"\(privateKey)\")",
                "-subj \"/CN=\(commonName)\"",
            ].compactMap { $0 },
            log: .commandAndOutput(outputLogLevel: .verbose),
            maskSubstringsInLog: [privateKey],
            silentStdErrMessages: false
        )

        let stdout = try output.stdoutText.unwrap(errorDescription: "csr stdout is nil.")
        let stderr = output.stderrText ?? "<nil>"

        guard
            stdout.starts(with: "-----BEGIN CERTIFICATE REQUEST-----")
        else {
            throw Errors.badCSRParsed(stdout: stdout, stderr: stderr)
        }

        return stdout
    }
}
