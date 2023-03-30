//

import Foundation
import SwiftlaneCore

public protocol PeripheryServicing {
    func scan(projectDir: AbsolutePath, indexStorePath: String, build: Bool) throws -> [PeripheryModels.ScanResult]
    func scan(projectDir: AbsolutePath, derivedDataPath: AbsolutePath, build: Bool) throws -> [PeripheryModels.ScanResult]
    func findIndexStorePath(derivedDataPath: AbsolutePath) throws -> AbsolutePath
}

public class PeripheryService {
    private let shell: ShellExecuting
    private let filesManager: FSManaging

    public init(shell: ShellExecuting, filesManager: FSManaging) {
        self.shell = shell
        self.filesManager = filesManager
    }
}

extension PeripheryService: PeripheryServicing {
    public func findIndexStorePath(derivedDataPath: AbsolutePath) throws -> AbsolutePath {
        let candidates = [
            try derivedDataPath.appending(path: "Index/DataStore"),
            try derivedDataPath.appending(path: "Index.noindex/DataStore"), // Xcode 14+
        ]
        return try candidates.first(where: filesManager.directoryExists).unwrap(
            errorDescription: "DataStore not found in derived data path \(derivedDataPath.string.quoted)"
        )
    }

    public func scan(
        projectDir: AbsolutePath,
        derivedDataPath: AbsolutePath,
        build: Bool
    ) throws -> [PeripheryModels.ScanResult] {
        let indexStorePath = try findIndexStorePath(derivedDataPath: derivedDataPath)
        return try scan(projectDir: projectDir, indexStorePath: indexStorePath.string, build: build)
    }

    /// - Parameter indexStorePath:
    /// 	for example `"~/Library/Developer/Xcode/DerivedData/YouProjectName-gsnskdfhsdfwdmmeejzhdvpmmw/Index/DataStore"`
    /// 	or use ``PeripheryServicing.findInexStorePath(derivedDataPath:)``
    public func scan(projectDir: AbsolutePath, indexStorePath: String, build: Bool) throws -> [PeripheryModels.ScanResult] {
        let output = try shell.run(
            [
                "cd \(projectDir.string.quoted) &&",
                "periphery scan",
                build ? "" : "--skip-build",
                "--index-store-path \(indexStorePath.quoted)",
                "--format json",
            ],
            log: .commandOnly
        ).stdoutText

        let outputData = try (output?.data(using: .utf8)).unwrap(
            errorDescription: "periphery scan output is nil or malformed."
        )

        return try JSONDecoder().decode([PeripheryModels.ScanResult].self, from: outputData)
    }
}
