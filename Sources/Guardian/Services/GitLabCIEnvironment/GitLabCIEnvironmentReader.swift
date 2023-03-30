//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol GitLabCIEnvironmentReading {
    func string(_ variable: GitLabCIEnvironmentVariable) throws -> String
    func int(_ variable: GitLabCIEnvironmentVariable) throws -> Int
    func double(_ variable: GitLabCIEnvironmentVariable) throws -> Double
    func bool(_ variable: GitLabCIEnvironmentVariable) throws -> Bool
    func url(_ variable: GitLabCIEnvironmentVariable) throws -> URL

    /// Formed like `$CI_PROJECT_URL/-/merge_requests/$CI_MERGE_REQUEST_IID`.
    func mergeRequestURL() throws -> URL

    /// Parses genius GitLab's formatted list of assignees from `CI_MERGE_REQUEST_ASSIGNEES` env variable.
    /// - Returns: array of gitlab usernames.
    func assigneesUsernames() throws -> [String]
}

public class GitLabCIEnvironmentReader {
    private let environmentValueReading: EnvironmentValueReading

    public init(
        environmentValueReading: EnvironmentValueReading
    ) {
        self.environmentValueReading = environmentValueReading
    }
}

extension GitLabCIEnvironmentReader: GitLabCIEnvironmentReading {
    public func string(_ variable: GitLabCIEnvironmentVariable) throws -> String {
        try environmentValueReading.string(variable.rawValue)
    }

    public func int(_ variable: GitLabCIEnvironmentVariable) throws -> Int {
        try environmentValueReading.int(variable.rawValue)
    }

    public func double(_ variable: GitLabCIEnvironmentVariable) throws -> Double {
        try environmentValueReading.double(variable.rawValue)
    }

    public func bool(_ variable: GitLabCIEnvironmentVariable) throws -> Bool {
        try environmentValueReading.bool(variable.rawValue)
    }

    public func url(_ variable: GitLabCIEnvironmentVariable) throws -> URL {
        try environmentValueReading.url(variable.rawValue)
    }

    public func mergeRequestURL() throws -> URL {
        let projectURL = try url(.CI_PROJECT_URL)
        let mergeRequestIID = try string(.CI_MERGE_REQUEST_IID)

        return projectURL
            .appendingPathComponent("/-/merge_requests/")
            .appendingPathComponent(mergeRequestIID)
    }

    public func assigneesUsernames() throws -> [String] {
        /// Note: GitLab Documentation of values of `CI_MERGE_REQUEST_ASSIGNEES` env variable is not accurate.
        ///
        /// Really possible values are:
        /// * `kevin78, kimjason, and williammartinez`
        ///	* `kevin78 and williammartinez`
        /// * `kevin78`
        try string(.CI_MERGE_REQUEST_ASSIGNEES)
            .components(separatedBy: " and ")
            .flatMap { $0.components(separatedBy: ",") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
