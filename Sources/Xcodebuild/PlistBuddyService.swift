//

import Foundation
import SwiftlaneCore

public protocol PlistBuddyServicing {
    func set(variableNameOrPath: String, value: String, plist: AbsolutePath) throws
    func read(variableName: String, from plist: AbsolutePath) throws -> String?
}

public final class PlistBuddyService {
    private let binary: String = "/usr/libexec/PlistBuddy"

    private let shell: ShellExecuting

    public init(
        shell: ShellExecuting
    ) {
        self.shell = shell
    }
}

public enum InfoPlistKeys {
    public static var bundleShortVersionString: String { "CFBundleShortVersionString" }
    public static var bundleVersion: String { "CFBundleVersion" }
}

extension PlistBuddyService: PlistBuddyServicing {
    public func set(variableNameOrPath: String, value: String, plist: AbsolutePath) throws {
        try shell.run(
            [
                "\(binary)",
                "-c 'Set :\(variableNameOrPath) \(value)'",
                "\(plist.string.quoted)",
            ],
            log: .commandAndOutput(outputLogLevel: .debug)
        )
    }

    public func read(variableName: String, from plist: AbsolutePath) throws -> String? {
        let output = try shell.run(
            [
                "\(binary)",
                "-c 'Print :\(variableName)'",
                "\(plist.string.quoted)",
            ],
            log: .commandAndOutput(outputLogLevel: .debug)
        )

        return output.stdoutText?.deletingSuffix("\n") /// PlistBuddy always prints "\n" at the end.
    }
}
