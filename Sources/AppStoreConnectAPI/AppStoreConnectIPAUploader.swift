//

import Foundation
import SwiftlaneCore

public enum AppStoreConnectIPAUploaderType: String, CaseIterable {
    /// Preferred. Crossplatform, java-backed.
    case iTMSTransporter
    /// Sometimes doesn't work at all.
    case altool
}

public protocol AppStoreConnectIPAUploading {
    /// Upload `.ipa` to AppStoreConnect.
    func upload(ipaPath: AbsolutePath, using uploader: AppStoreConnectIPAUploaderType) throws
}

public final class AppStoreConnectIPAUploader {
    public struct Config {
        /// Path to your `AuthKey_XXXXXX.p8` file.
        public let authKeyPath: AbsolutePath
        /// Your issuer ID from the API Keys page in App Store Connect;
        /// for example, 57246542-96fe-1a63-e053-0824d011072a.
        public let authKeyIssuerID: String

        /// If you specify a filename, Transporter logs the output to the specified file, as well as to standard out.
        public let logDir: AbsolutePath?

        /// - Parameter authKeyPath: Path to your `AuthKey_XXXXXX.p8` file.
        /// - Parameter authKeyIssuerID: Your issuer ID from the API Keys page in App Store Connect;
        ///   for example, 57246542-96fe-1a63-e053-0824d011072a.
        public init(
            authKeyPath: AbsolutePath,
            authKeyIssuerID: String,
            logDir: AbsolutePath?
        ) {
            self.authKeyPath = authKeyPath
            self.authKeyIssuerID = authKeyIssuerID
            self.logDir = logDir
        }
    }

    private let logger: Logging
    private let filesManager: FSManaging
    private let shell: ShellExecuting
    private let tokenGenerator: AppStoreConnectTokenGenerator
    private let config: Config
    private let authKeyIDParser: AppStoreConnectAuthKeyIDParsing

    public init(
        logger: Logging,
        filesManager: FSManaging,
        shell: ShellExecuting,
        tokenGenerator: AppStoreConnectTokenGenerator,
        authKeyIDParser: AppStoreConnectAuthKeyIDParsing,
        config: Config
    ) {
        self.logger = logger
        self.filesManager = filesManager
        self.shell = shell
        self.tokenGenerator = tokenGenerator
        self.authKeyIDParser = authKeyIDParser
        self.config = config
    }
}

extension AppStoreConnectIPAUploader: AppStoreConnectIPAUploading {
    public func upload(ipaPath: AbsolutePath, using uploader: AppStoreConnectIPAUploaderType) throws {
        logger.important("Going to upload \(ipaPath.string.quoted) to AppStoreConnect using \(uploader.rawValue)")

        switch uploader {
        case .iTMSTransporter:
            let logFile = try config.logDir?.appending(
                path: "\(ipaPath.lastComponent.string)_\(Date().full_custom).log"
            )

            config.logDir.map {
                try? filesManager.mkdir($0)
            }

            let token = try tokenGenerator.token(lifetime: 20 * 60)

            try shell.run(
                [
                    "xcrun iTMSTransporter",
                    "-v informational", // less verbose logging
                    "-m upload",
                    "-simpleLogDefaultLog info", // less verbose logging
                    "-jwt " + token.jwtString,
                    "-assetFile " + ipaPath.string.quoted,
                    "-k 100000", // throttle speed is a required option so we set it to 100mbit/s
                    "-throughput",
                    logFile.map {
                        "-o " + $0.string.quoted
                    },
                ].compactMap { $0 },
                log: .commandAndOutput(outputLogLevel: .info),
                maskSubstringsInLog: [token.jwtString]
            )

        case .altool:
            let apiKeyID = try authKeyIDParser.apiKeyID(from: config.authKeyPath.lastComponent.string)

            try shell.run(
                [
                    "API_PRIVATE_KEYS_DIR=" + config.authKeyPath.deletingLastComponent.string.quoted,
                    "xcrun altool --upload-app",
                    "--file " + ipaPath.string.quoted,
                    "--apiKey " + apiKeyID.quoted,
                    "--apiIssuer " + config.authKeyIssuerID.quoted,
                    "--type ios",
                    "--show-progress",
                ],
                log: .commandAndOutput(outputLogLevel: .info),
                maskSubstringsInLog: [config.authKeyIssuerID]
            )
        }
    }
}
