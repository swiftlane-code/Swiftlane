//

import Combine
import Foundation
import Git
import Guardian
import Networking
import SwiftlaneCore
import Xcodebuild

public struct PatchTestPlanEnvTaskConfig {
    public let testPlanName: String
    public let projectDir: AbsolutePath
    public let patchVariablesWithNames: [StringMatcher]
    public let testPlanSearchExcludedDirs: [AbsolutePath]
    public let testPlanSearchIncludedDirs: [AbsolutePath]
}

public class PatchTestPlanEnvTask {
    private let logger: Logging
    private let filesManager: FSManaging
    private let environmentReader: EnvironmentValueReading
    private let config: PatchTestPlanEnvTaskConfig
    private let patcher: XCTestPlanPatching

    public init(
        logger: Logging,
        filesManager: FSManaging,
        environmentReader: EnvironmentValueReading,
        patcher: XCTestPlanPatching,
        config: PatchTestPlanEnvTaskConfig
    ) {
        self.logger = logger
        self.filesManager = filesManager
        self.environmentReader = environmentReader
        self.patcher = patcher
        self.config = config
    }

    public func findTestPlan() throws -> AbsolutePath {
        let allTestPlans = try filesManager.find(config.projectDir)
            .filter { $0.hasSuffix(".xctestplan") }
            .filter { testPlanPath in
                let matchingExcluded = config.testPlanSearchExcludedDirs.contains {
                    testPlanPath.hasPrefix($0.string)
                }
                return !matchingExcluded
            }
            .filter { testPlanPath in
                let matchingIncluded = config.testPlanSearchIncludedDirs.contains {
                    testPlanPath.hasPrefix($0.string)
                }
                return matchingIncluded
            }

        logger.verbose("Found test plans: \(allTestPlans)")

        let testPlanPath = try allTestPlans
            .filter {
                $0.lastComponent.string == config.testPlanName + ".xctestplan"
            }
            .first.unwrap(
                errorDescription: "Test plan with name \(config.testPlanName.quoted) not found."
            )

        return testPlanPath
    }

    public func patchEnvVariables() throws {
        logger.important("Patching test plan \(config.testPlanName.quoted) environment variables...")

        let testPlanPath = try findTestPlan()

        let data = try filesManager.readData(testPlanPath, log: true)

        let variablesToPatch = environmentReader.allVariables.filter {
            config.patchVariablesWithNames.isMatching(string: $0.key)
        }

        let patchedData = try patcher.patchEnvironmentVariables(data: data, with: variablesToPatch)

        try filesManager.write(testPlanPath, data: patchedData)
    }

    public func run() throws {
        try patchEnvVariables()
    }
}
