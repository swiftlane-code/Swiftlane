//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol ProvisioningProfilesServicing {
    /// Installs a provisioning profile into system directory
    /// `~/Library/Developer/Xcode/UserData/Provisioning Profiles`
    ///
    /// - Returns: parsed profile info and it's installed path.
    @discardableResult
    func installProvisioningProfile(
        path: AbsolutePath
    ) throws -> (profile: MobileProvision, installedPath: AbsolutePath)

    /// Looks for a provisioning profile with specified `name` in system directory
    /// `~/Library/Developer/Xcode/UserData/Provisioning Profiles`
    ///
    /// - Returns: parsed profile info and it's path.
    @discardableResult
    func findProvisioningProfile(named name: String) throws -> (profile: MobileProvision, path: AbsolutePath)
}

public final class ProvisioningProfilesService {
    public enum Errors: Error {
        case unsupportedProvisioningProfileExtension(path: AbsolutePath)
        case profileWithNameNotFound(name: String)
        case foundOnlyExpiredProfile(name: String, profile: MobileProvision, path: AbsolutePath)
    }

    private let filesManager: FSManaging
    private let logger: Logging
    private let provisionProfileParser: MobileProvisionParsing

    public init(
        filesManager: FSManaging,
        logger: Logging,
        provisionProfileParser: MobileProvisionParsing
    ) {
        self.filesManager = filesManager
        self.logger = logger
        self.provisionProfileParser = provisionProfileParser
    }

    private func installDir() throws -> AbsolutePath {
        // Xcode 16+ uses unified location for both iOS and macOS provisioning profiles
        try filesManager.homeDirectoryForCurrentUser()
            .appending(path: "Library/Developer/Xcode/UserData/Provisioning Profiles")
    }

    private func validFileExtensions() -> [StringMatcher] {
        [
            .hasSuffix(".mobileprovision"), // iOS, iPadOS, tvOS, watchOS
            .hasSuffix(".provisionprofile")  // macOS
        ]
    }
}

extension ProvisioningProfilesService: ProvisioningProfilesServicing {
    /// Installs a provisioning profile into system directory
    /// `~/Library/Developer/Xcode/UserData/Provisioning Profiles`
    ///
    /// - Returns: parsed profile info and it's installed path.
    @discardableResult
    public func installProvisioningProfile(path: AbsolutePath) throws -> (
        profile: MobileProvision,
        installedPath: AbsolutePath
    ) {
        guard validFileExtensions().isMatching(string: path.string) else {
            throw Errors.unsupportedProvisioningProfileExtension(path: path)
        }

        let installDir = try installDir()

        logger.debug("Installing \(path.lastComponent.string.quoted)...")

        let provision = try provisionProfileParser.parse(provisionPath: path)
        let installPath = try installDir.appending(path: provision.UUID + "." + path.pathExtension)

        if filesManager.fileExists(installPath) {
            logger.debug("\(installPath.string.quoted) already exists, replacing it.")
            try filesManager.delete(installPath)
        }

        try filesManager.copy(path, to: installPath)
        logger.success("\(provision.Name.quoted) installed.")

        return (provision, installPath)
    }

    /// Looks for a provisioning profile with specified `name` in system directory
    /// `~/Library/Developer/Xcode/UserData/Provisioning Profiles`
    ///
    /// - Returns: parsed profile info and it's path.
    public func findProvisioningProfile(named name: String) throws -> (profile: MobileProvision, path: AbsolutePath) {
        let installDir = try installDir()

        logger.important("Looking for installed provisioning profile with name \(name.quoted)...")

        let profiles = try filesManager.ls(installDir).filter {
            validFileExtensions().isMatching(string: $0.string)
        }.map { path in
            (profile: try provisionProfileParser.parse(provisionPath: path), path: path)
        }

        let candidates = profiles.filter { profile, _ in
            profile.Name == name
        }.sorted { lhs, rhs in
            lhs.profile.ExpirationDate > rhs.profile.ExpirationDate // first date will be the latest-in-time
        }

        guard let result = candidates.first else {
            logger.error("Profile with name \(name.quoted) not found in \(installDir.string.quoted).")
            logger.debug(
                "Existing profiles: \n" + profiles.map {
                    "\($0.profile.Name.quoted) -> \($0.path.string.quoted)"
                }.joined(separator: "\n")
            )

            throw Errors.profileWithNameNotFound(name: name)
        }

        guard result.profile.ExpirationDate > Date() else {
            logger.error("Found only expired profile at path \(result.path.string.quoted): \n" + result.profile.asPrettyJSON())
            throw Errors.foundOnlyExpiredProfile(name: name, profile: result.profile, path: result.path)
        }

        logger.important("Found provisioning profile with name \(name.quoted) at \(result.path.string.quoted).")
        logger.verbose(result.profile.asPrettyJSON())

        return result
    }
}
