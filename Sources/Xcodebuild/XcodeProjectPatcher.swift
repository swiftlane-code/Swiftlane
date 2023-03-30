//

import Foundation
import SwiftlaneCore
import XcodeProj

public protocol XcodeProjectPatching {
    /// Set provisioning profile for target.
    func setProvisionProfile(
        xcodeprojPath: AbsolutePath,
        schemeName: String,
        configurationName: String,
        profileUUID: String,
        profileName: String
    ) throws

    /// Get current `CFBudleShortVersionString` value in `Info.plist` files of one target.
    ///
    /// Be carefull when using this method as it is not guarantied which `Info.plist` is read.
    /// Do NOT use this method if you have different values of CFBundleShortVersionString in different
    /// Info.plist files inside your project folder.
    /// Check this by running `$ agvtool what-marketing-version`
    func getMarketingVersion(
        projectDir: AbsolutePath
    ) throws -> String

    /// Updates `CFBudleShortVersionString` value in `Info.plist` files of all targets.
    func setMarketingVersionForAllTargets(
        projectDir: AbsolutePath,
        marketingVersion: String
    ) throws

    /// Change `CFBundleVersion` value in Info.plist files.
    func setCFBundleVersion(
        xcodeprojPath: AbsolutePath,
        value: String
    ) throws

    /// Change `CURRENT_PROJECT_VERSION` value in Build Settings.
    func setCurrentProjectVersion(
        xcodeprojPath: AbsolutePath,
        value: String
    ) throws
}

public final class XcodeProjectPatcher {
    public enum Errors: Error {
        case emptyBuildNumberSupplied
        case emptyMarketingVersionSupplied
        case invalidBundleVersion(String, allowedRegex: String)
        case noPlistsFound
    }

    private let logger: Logging
    private let shell: ShellExecuting
    private let plistBuddyService: PlistBuddyServicing

    /// Regex to match valid `CFBundleVersion` value.
    /// * Regex is for string matching digits separated with dots.
    /// * Dots on the first and last place is not allowed.
    /// * Single digit is allowed.
    let allowedBundleVersionValueRegex = try! NSRegularExpression(pattern: #"^\d[\d\.]*(?<=\d)$"#)

    public init(
        logger: Logging,
        shell: ShellExecuting,
        plistBuddyService: PlistBuddyServicing
    ) {
        self.logger = logger
        self.shell = shell
        self.plistBuddyService = plistBuddyService
    }

    private func logChange(_ msg: String, from prevValue: String?, to newValue: String?) {
        let prevValue = prevValue?.quoted ?? "<nil>"
        let newValue = newValue?.quoted ?? "<nil>"
        logger.important(msg + " from \(prevValue) to \(newValue)")
    }
}

extension XcodeProjectPatcher: XcodeProjectPatching {
    //	/// - Returns: `[ <bundle.id> : <provision profile UUID or Name> ]`
    //	public func getProvisioningProfileSpecifiers(
    //		xcodeprojPath: AbsolutePath,
    //		configurationName: String
    //	) throws -> [String: String] {
    //		logger.log("Getting provisioning profiles specifiers for all targets for configuration \"\(configurationName)\".")
//
    //		let xcodeproj: XcodeProj
    //		do {
    //			xcodeproj = try XcodeProj(pathString: xcodeprojPath.string)
    //		} catch {
    //			logger.error("Failed to parse xcodeproj \"\(xcodeprojPath.string)\"")
    //			throw error
    //		}
//
    //		let profiles: [String: String] = try xcodeproj.pbxproj.nativeTargets.reduce(into: [:]) { result, target in
    //			let buildConfigurationList = try target.buildConfigurationList.unwrap(
    //				errorDescription: "Build Configuration List of target \"\(target.name)\" is nil."
    //			)
//
    //			let configuration = try buildConfigurationList.configuration(name: configurationName).unwrap(
    //				errorDescription: "Build Configuration with name \"\(configurationName)\" not found for target \"\(target.name)\""
    //			)
//
    //			guard let profileSpecifier = configuration.buildSettings["PROVISIONING_PROFILE_SPECIFIER"] else {
    //				logger.log("Target \"\(target.name)\" has no PROVISIONING_PROFILE_SPECIFIER.")
    //				return
    //			}
//
    //			let bundleID = try configuration.buildSettings["PRODUCT_BUNDLE_IDENTIFIER"].unwrap(
    //				errorDescription: "PRODUCT_BUNDLE_IDENTIFIER is not set for \(configuration.name) configuration of \(target.name) target."
    //			)
//
    //			result[bundleID] = profileSpecifier
    //		}
    //	}

    public func setProvisionProfile(
        xcodeprojPath: AbsolutePath,
        schemeName: String,
        configurationName: String,
        profileUUID: String,
        profileName: String
    ) throws {
        logger.important("Going to set provisioning profile \"\(profileName)\" for \(schemeName) scheme (\(configurationName)).")

        let xcodeproj: XcodeProj
        do {
            xcodeproj = try XcodeProj(pathString: xcodeprojPath.string)
        } catch {
            logger.error("Failed to parse xcodeproj \"\(xcodeprojPath.string)\"")
            throw error
        }

        let scheme = try (xcodeproj.sharedData?.schemes.first { $0.name == schemeName }).unwrap(
            errorDescription: "Scheme named \"\(schemeName)\" not found in \"\(xcodeprojPath)\"."
        )

        let productName = try (scheme.launchAction?.runnable?.buildableReference?.buildableName).unwrap(
            errorDescription: "Unable to get runnable product name from scheme named \"\(scheme.name)\""
        )

        let target = try xcodeproj.pbxproj.nativeTargets.first { $0.productNameWithExtension() == productName }.unwrap(
            errorDescription: "Target with product named \"\(productName)\" not found in \"\(xcodeprojPath)\"."
        )

        let buildConfigurationList = try target.buildConfigurationList.unwrap(
            errorDescription: "Build Configuration List of target \"\(target.name)\" is nil."
        )

        let configuration = try buildConfigurationList.configuration(name: configurationName).unwrap(
            errorDescription: "Build Configuration with name \"\(configurationName)\" not found for target \"\(target.name)\""
        )

        logger.important("Updating build settings of target '\(target.name)' for '\(configuration.name)' configuration.")
        configuration.buildSettings["PROVISIONING_PROFILE"] = profileUUID
        configuration.buildSettings["PROVISIONING_PROFILE_SPECIFIER"] = profileName
        configuration.buildSettings["CODE_SIGN_STYLE"] = nil // Manual

        logger.important("Writing modified xcodeproj...")
        try xcodeproj.write(pathString: xcodeprojPath.string, override: true)

        logger.success("Provisioning profile updated.")
    }

    /// Change `CFBundleVersion` value in Info.plist files.
    public func setCFBundleVersion(
        xcodeprojPath: AbsolutePath,
        value: String
    ) throws {
        guard allowedBundleVersionValueRegex.isMatching(string: value) else {
            throw Errors.invalidBundleVersion(value, allowedRegex: allowedBundleVersionValueRegex.pattern)
        }

        logger.important("Going to set \(InfoPlistKeys.bundleVersion) in all Info.plist files to \"\(value)\".")

        let xcodeproj: XcodeProj
        do {
            xcodeproj = try XcodeProj(pathString: xcodeprojPath.string)
        } catch {
            logger.error("Failed to parse xcodeproj \"\(xcodeprojPath.string)\"")
            throw error
        }

        var patched: Set<AbsolutePath> = []

        try xcodeproj.pbxproj.buildConfigurations.forEach { buildConfig in
            let plistFileBuildSetting = buildConfig.buildSettings["INFOPLIST_FILE"] as? String
            logger.verbose("\(buildConfig.name) INFOPLIST_FILE: \(String(describing: plistFileBuildSetting))")

            guard let plistPathString = plistFileBuildSetting,
                  let plistPath = try? Path(plistPathString)
            else {
                logger.warn("INFOPLIST_FILE value is not a path")
                return
            }

            let absPlistPath = plistPath.makeAbsoluteIfIsnt(relativeTo: xcodeprojPath.deletingLastComponent)
            guard !patched.contains(absPlistPath) else {
                return
            }
            patched.insert(absPlistPath)

            let prevValue = try? plistBuddyService.read(
                variableName: InfoPlistKeys.bundleVersion,
                from: absPlistPath
            )

            logChange("Changing \(InfoPlistKeys.bundleVersion) in \(plistPath)", from: prevValue, to: value)

            try plistBuddyService.set(
                variableNameOrPath: InfoPlistKeys.bundleVersion,
                value: value,
                plist: absPlistPath
            )
        }

        logger.verbose("Updated plists: \n\(patched.map(\.string).joined(separator: "\n"))")
        logger.success("Updated \(patched.count) plists.")

        if patched.isEmpty {
            throw Errors.noPlistsFound
        }
    }

    /// Change `CURRENT_PROJECT_VERSION` value in Build Settings.
    public func setCurrentProjectVersion(
        xcodeprojPath: AbsolutePath,
        value: String
    ) throws {
        guard allowedBundleVersionValueRegex.isMatching(string: value) else {
            throw Errors.invalidBundleVersion(value, allowedRegex: allowedBundleVersionValueRegex.pattern)
        }

        let buildSettingsKey = "CURRENT_PROJECT_VERSION"

        logger.important("Going to set \(buildSettingsKey) of all targets to \"\(value)\".")

        let xcodeproj: XcodeProj
        do {
            xcodeproj = try XcodeProj(pathString: xcodeprojPath.string)
        } catch {
            logger.error("Failed to parse xcodeproj \"\(xcodeprojPath.string)\"")
            throw error
        }

        xcodeproj.pbxproj.nativeTargets.forEach { target in
            target.buildConfigurationList?.buildConfigurations.forEach { targetBuildConfig in
                logChange(
                    "Changing \(buildSettingsKey) of target \(target.name)",
                    from: targetBuildConfig.buildSettings[buildSettingsKey] as? String,
                    to: nil
                )
                targetBuildConfig.buildSettings[buildSettingsKey] = nil
            }
        }

        try xcodeproj.pbxproj.rootProject()?.buildConfigurationList.buildConfigurations
            .forEach { buildConfig in
                logChange(
                    "Changing \(buildSettingsKey) of project",
                    from: buildConfig.buildSettings[buildSettingsKey] as? String,
                    to: value
                )
                buildConfig.buildSettings[buildSettingsKey] = value
            }

        logger.important("Writing modified xcodeproj...")
        try xcodeproj.write(pathString: xcodeprojPath.string, override: true)

        logger.success("Values of \(buildSettingsKey) updated.")
    }

    public func getMarketingVersion(
        projectDir: AbsolutePath
    ) throws -> String {
        let commandResult = try shell.run(
            "cd \"\(projectDir)\" && agvtool what-marketing-version -terse1",
            log: .commandAndOutput(outputLogLevel: .info)
        )

        let result = try commandResult.stdoutText.unwrap(errorDescription: "nil output of command")

        logger.success("Marketing version is \(result)")

        return result
    }

    public func setMarketingVersionForAllTargets(
        projectDir: AbsolutePath,
        marketingVersion: String
    ) throws {
        let marketingVersion = marketingVersion.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !marketingVersion.isEmpty else {
            throw Errors.emptyMarketingVersionSupplied
        }

        logger.important("Going to set marketing version of all targets to \"\(marketingVersion)\".")

        try shell.run(
            "cd \"\(projectDir)\" && agvtool new-marketing-version \"\(marketingVersion)\"",
            log: .commandAndOutput(outputLogLevel: .info)
        )

        logger.success("Marketing version updated.")
    }
}
