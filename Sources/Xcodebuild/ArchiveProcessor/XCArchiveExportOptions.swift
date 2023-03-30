//

import Foundation

public struct XCArchiveExportOptions: Codable {
    public enum Destination: String, Codable {
        case export
        case upload
    }

    public enum ExportMethod: String, Codable, CaseIterable {
        case appStore = "app-store"
        case validation
        case adHoc = "ad-hoc"
        case package
        case enterprise
        case development
        case developerId = "developer-id"
        case macApplication = "mac-application"
    }

    public enum SigningStyle: String, Codable {
        case automatic
        case manual
    }

    public init() {}

    /// For non-App Store exports, should Xcode re-compile the app from bitcode? Defaults to YES.
    public var compileBitcode: Bool?

    /// Determines whether the app is exported locally or uploaded to Apple. Options are export or upload. The available options vary based on the selected distribution method. Defaults to export.
    public var destination: Destination?

    /// Reformat archive to focus on eligible target bundle identifier.
    public var distributionBundleIdentifier: String?

    /// For non-App Store exports, if the app uses On Demand Resources and this is YES, asset packs are embedded in the app bundle so that the app can be tested without a server to host asset packs. Defaults to YES unless onDemandResourcesAssetPacksBaseURL is specified.
    public var embedOnDemandResourcesAssetPacksInBundle: Bool?

    /// For App Store exports, should Xcode generate App Store Information for uploading with iTMSTransporter? Defaults to NO.
    public var generateAppStoreInformation: Bool?

    /// If the app is using CloudKit, this configures the "com.apple.developer.icloud-container-environment" entitlement. Available options vary depending on the type of provisioning profile used, but may include: Development and Production.
    public var iCloudContainerEnvironment: String?

    /// For manual signing only. Provide a certificate name, SHA-1 hash, or automatic selector to use for signing. Automatic selectors allow Xcode to pick the newest installed certificate of a particular type. The available automatic selectors are "Developer ID Installer" and "Mac Installer Distribution". Defaults to an automatic certificate selector matching the current distribution method.
    public var installerSigningCertificate: String?

    /// Should Xcode manage the app's build number when uploading to App Store Connect? Defaults to YES.
    public var manageAppVersionAndBuildNumber: Bool?

    /// For non-App Store exports, users can download your app over the web by opening your distribution manifest file in a web browser. To generate a distribution manifest, the value of this key should be a dictionary with three sub-keys: appURL, displayImageURL, fullSizeImageURL. The additional sub-key assetPackManifestURL is required when using on-demand resources.
    public var manifest: [String: String]?

    /// Describes how Xcode should export the archive. Available options: app-store, validation, ad-hoc, package, enterprise, development, developer-id, and mac-application. The list of options varies based on the type of archive. Defaults to development.
    public var method: ExportMethod?

    /// For non-App Store exports, if the app uses On Demand Resources and embedOnDemandResourcesAssetPacksInBundle isn't YES, this should be a base URL specifying where asset packs are going to be hosted. This configures the app to download asset packs from the specified URL.
    public var onDemandResourcesAssetPacksBaseURL: String?

    /// For manual signing only. Specify the provisioning profile to use for each executable in your app. Keys in this dictionary are the bundle identifiers of executables; values are the provisioning profile name or UUID to use.
    public var provisioningProfiles: [String: String]?

    /// For manual signing only. Provide a certificate name, SHA-1 hash, or automatic selector to use for signing. Automatic selectors allow Xcode to pick the newest installed certificate of a particular type. The available automatic selectors are "Mac App Distribution", "iOS Distribution", "iOS Developer", "Developer ID Application", "Apple Distribution", "Mac Developer", and "Apple Development". Defaults to an automatic certificate selector matching the current distribution method.
    public var signingCertificate: String?

    /// The signing style to use when re-signing the app for distribution. Options are manual or automatic. Apps that were automatically signed when archived can be signed manually or automatically during distribution, and default to automatic. Apps that were manually signed when archived must be manually signed during distribtion, so the value of signingStyle is ignored.
    public var signingStyle: SigningStyle?

    /// Should symbols be stripped from Swift libraries in your IPA? Defaults to YES.
    public var stripSwiftSymbols: Bool?

    /// The Developer Portal team to use for this export. Defaults to the team used to build the archive.
    public var teamID: String?

    /// For non-App Store exports, should Xcode thin the package for one or more device variants? Available options: <none> (Xcode produces a non-thinned universal app), <thin-for-all-variants> (Xcode produces a universal app and all available thinned variants), or a model identifier for a specific device (e.g. "iPhone7,1"). Defaults to <none>.
    public var thinning: String?

    /// For App Store exports, should the package include bitcode? Defaults to YES.
    public var uploadBitcode: Bool?

    /// For App Store exports, should the package include symbols? Defaults to YES.
    public var uploadSymbols: Bool?
}
