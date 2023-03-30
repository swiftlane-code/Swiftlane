//

import Foundation
import SwiftlaneCore

public protocol XCTestPlanPatching {
    func patchEnvironmentVariables(data: Data, with variablesToPatch: [String: String]) throws -> Data
}

public class XCTestPlanPatcher: XCTestPlanPatching {
    private enum Keys {
        static var defaultOptions = "defaultOptions"
        static var environmentVariableEntries = "environmentVariableEntries"
        static var key = "key"
        static var value = "value"
    }

    private let logger: Logging
    private let filesManager: FSManaging
    private let environmentReader: EnvironmentValueReading

    public init(
        logger: Logging,
        filesManager: FSManaging,
        environmentReader: EnvironmentValueReading
    ) {
        self.logger = logger
        self.filesManager = filesManager
        self.environmentReader = environmentReader
    }

    /// Patches env variables section of test plan json (path is `defaultOptions.environmentVariableEntries`).
    ///
    /// * Keeps all defined env variables and ALL OTHER JSON DATA already defined in test plan's json.
    /// * Overwrites existing values of any variable from `variablesToPatch` if it is already defined in the test plan's json.
    ///
    /// - Parameters:
    ///   - data: data of test plan json.
    ///   - variablesToPatch: varaibles to be injected into test plan json data.
    /// - Returns: patched json data.
    public func patchEnvironmentVariables(data: Data, with variablesToPatch: [String: String]) throws -> Data {
        let json = try cast(
            JSONSerialization.jsonObject(
                with: data,
                options: [.mutableContainers, .mutableLeaves]
            ),
            to: NSDictionary.self
        )

        let defaultOptions = try (json[Keys.defaultOptions] as? NSMutableDictionary).unwrap(
            errorDescription: "Top level key \(Keys.defaultOptions.quoted) not found in parsed test plan."
        )
        let environmentVariableEntries = defaultOptions[Keys.environmentVariableEntries] as? NSArray

        // swiftformat:disable trailingClosures
        let existingVariables = environmentVariableEntries?
            .compactMap { $0 as? NSDictionary }
            .reduce(into: [String: String](), { partialResult, pair in
                guard
                    let key = pair[Keys.key] as? NSString,
                    let value = pair[Keys.value] as? NSString
                else {
                    return
                }
                partialResult[String(key)] = String(value)
            }) ?? [:]
        // swiftformat:enable trailingClosures

        logger.important("Parsed environmentVariableEntries: \(String(describing: existingVariables))")

        logger.important("Variables to patch: \(variablesToPatch)")

        let resultingEnv = existingVariables.merging(variablesToPatch, uniquingKeysWith: { $1 })

        let finalEnvironmentVariableEntries = NSMutableArray(
            array: resultingEnv.sorted {
                $0.key > $1.key
            }.map {
                NSDictionary(dictionary: [
                    Keys.key: $0.key,
                    Keys.value: $0.value,
                ])
            }
        )
        defaultOptions[Keys.environmentVariableEntries] = finalEnvironmentVariableEntries

        logger.important("Resulting environment: \(finalEnvironmentVariableEntries)")

        let patchedData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])

        return patchedData
    }
}
