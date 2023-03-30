
import ArgumentParser
import Foundation
import SwiftlaneCore

public protocol UploadGitLabPackageCommandParamsAccessing {
    var sharedConfigOptions: SharedConfigOptions { get }

    var projectID: UInt { get }
    var packageName: String { get }
    var packageVersion: String { get }
    var file: AbsolutePath { get }
    var uploadedFileName: String? { get }
    var timeoutSeconds: TimeInterval { get }
}

public struct UploadGitLabPackageCommand: ParsableCommand, UploadGitLabPackageCommandParamsAccessing {
    public static var configuration = CommandConfiguration(
        commandName: "upload-gitlab-package",
        abstract: "Uploads a package to GitLab packages"
    )

    @OptionGroup public var sharedConfigOptions: SharedConfigOptions

    @Option(help: "GitLab project ID.")
    public var projectID: UInt

    @Option(help: "Name of new package.")
    public var packageName: String

    @Option(help: "Version of new package.")
    public var packageVersion: String

    @Option(help: "Path to file which should be uploaded.")
    public var file: AbsolutePath

    @Option(help: "File name in the GitLab package. Defaults to name of file from --file value.")
    public var uploadedFileName: String?

    @Option(help: "Upload timeout.")
    public var timeoutSeconds: TimeInterval = 600

    public init() {}

    public mutating func run() throws {
        UploadGitLabPackageCommandRunner().run(self, sharedConfigOptions: sharedConfigOptions)
    }
}
