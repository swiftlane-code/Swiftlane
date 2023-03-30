//

import Foundation
import SwiftlaneCore
import Yams

public class SharedConfigReader {
    private let logger: Logging
    private let filesManager: FSManaging

    public init(
        logger: Logging,
        filesManager: FSManaging
    ) {
        self.logger = logger
        self.filesManager = filesManager
    }

    public func read(sharedConfigPath: AbsolutePath, overridesFrom commandConfigPath: AbsolutePath?) throws -> SharedConfigModel {
        let overridesKey = "sharedConfigOverrides"

        func justDecodeSharedConfig() throws -> SharedConfigModel {
            try YAMLDecoder().decode(SharedConfigModel.self, from: sharedConfigText)
        }

        // read configs text

        let sharedConfigText = try filesManager.readText(sharedConfigPath, log: false)

        guard let commandConfigPath = commandConfigPath else {
            return try justDecodeSharedConfig()
        }
        let commandConfigText = try filesManager.readText(commandConfigPath, log: false)

        guard !commandConfigText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.warn("Config at \(commandConfigPath.string.quoted) is empty")
            return try justDecodeSharedConfig()
        }

        // parse dictionaries from configs text

        let sharedConfigDict = try (Yams.load(yaml: sharedConfigText) as? [AnyHashable: Any]).unwrap(
            errorDescription: "\(sharedConfigPath.string.quoted) config can not be represented as a Dictionary"
        )
        let commandConfigDict = try (Yams.load(yaml: commandConfigText) as? [AnyHashable: Any]).unwrap(
            errorDescription: "\(commandConfigPath.string.quoted) config can not be represented as a Dictionary"
        )

        guard let overridesValue = commandConfigDict[overridesKey] else {
            logger.important("Config at \(commandConfigPath.string.quoted) has no shared config overrides (at key: \(overridesKey))")
            return try justDecodeSharedConfig()
        }

        let overridesDict = try (overridesValue as? [AnyHashable: Any]).unwrap(
            errorDescription: "\(commandConfigPath.string.quoted) config value under \(overridesKey.quoted) key can not be represented as a Dictionary"
        )

        // merge configs as dictionaries

        /// Merge nested inner dictionaries down to the leaves.
        func deepMerge(dict1: [AnyHashable: Any], dict2: [AnyHashable: Any]) -> [AnyHashable: Any] {
            dict1.merging(dict2, uniquingKeysWith: {
                guard
                    let innerDict1 = $0 as? [AnyHashable: Any],
                    let innerDict2 = $1 as? [AnyHashable: Any]
                else {
                    let loggedOldValue = (try? Yams.dump(object: $0)) ?? String(describing: $0)
                    let loggedNewValue = (try? Yams.dump(object: $1)) ?? String(describing: $1)
                    logger.important([
                        "Patching value:",
                        loggedOldValue.bold,
                        "replacing it with:",
                        loggedNewValue.bold,
                    ].joined(separator: "\n"))
                    return $1
                }
                return deepMerge(dict1: innerDict1, dict2: innerDict2)
            })
        }

        let overridenSharedConfigDict = deepMerge(dict1: sharedConfigDict, dict2: overridesDict)

        // decode shared config model from merged dictionary

        let overridenSharedConfigText = try Yams.dump(object: overridenSharedConfigDict)

        // swiftformat:disable indent
		logger.debug(
			"Decoding shared config from merged data of " +
			"shared config at \(sharedConfigPath.string.quoted) " +
			"and command config at \(commandConfigPath.string.quoted)\n\n" +
			overridenSharedConfigText.bold
		)
		// swiftformat:enable indent

        return try YAMLDecoder().decode(SharedConfigModel.self, from: overridenSharedConfigText)
    }
}
