//

import Foundation
import SwiftlaneCore

public struct XCLogParserIssuesReport: Codable {
    public let errors: [Issue]
    public let warnings: [Issue]

    /// https://github.com/MobileNativeFoundation/XCLogParser/blob/master/Sources/XCLogParser/parser/Notice.swift
    public struct Issue: Codable, Equatable {
        /// https://github.com/MobileNativeFoundation/XCLogParser/blob/master/Sources/XCLogParser/parser/NoticeType.swift
        /// The type of a Notice
        public enum IssueType: String, Codable, Equatable {
            /// Notes
            case note

            /// A warning thrown by the Swift compiler
            case swiftWarning

            /// A warning thrown by the C compiler
            case clangWarning

            /// A warning at a project level. For instance:
            /// "Warning Swift 3 mode has been deprecated and will be removed in a later version of Xcode"
            case projectWarning

            /// An error in a non-compilation step. For instance creating a directory or running a shell script phase
            case error

            /// An error thrown by the Swift compiler
            case swiftError

            /// An error thrown by the C compiler
            case clangError

            /// A warning returned by Xcode static analyzer
            case analyzerWarning

            /// A warning inside an Interface Builder file
            case interfaceBuilderWarning

            /// A warning about the usage of a deprecated API
            case deprecatedWarning

            /// Error thrown by the Linker
            case linkerError

            /// Error loading Swift Packages
            case packageLoadingError

            /// Error running a Build Phase's script
            case scriptPhaseError

            /// Failed command error (e.g. ValidateEmbeddedBinary, CodeSign)
            case failedCommandError
        }

        public let type: IssueType
        public let title: String
        public let clangFlag: String?
        public let documentURL: String
        public let severity: Int
        public let startingLineNumber: UInt64
        public let endingLineNumber: UInt64
        public let startingColumnNumber: UInt64
        public let endingColumnNumber: UInt64
        public let characterRangeEnd: UInt64
        public let characterRangeStart: UInt64
        public let interfaceBuilderIdentifier: String?
        public let detail: String?

        public var documentPath: AbsolutePath? {
            let string = URL(string: documentURL)?.path
            return try? string.map(AbsolutePath.init)
        }
    }
}
