//

import ArgumentParser
import Foundation
import Guardian
import SwiftlaneCore
import Yams

public protocol SwiftlaneCommandProtocol: ParsableCommand {
    var sharedConfigOptions: SharedConfigOptions { get }
}

/// Protocol of command runner.
///
/// Common logic of configs parsing etc is implemented in funcs inside extensions.
///
/// ``SharedConfig`` must be either `Void` or `SharedConfigData`.
public protocol CommandRunnerProtocol {
    associatedtype Command
    associatedtype Config
    associatedtype SharedConfig // SharedConfigData or Void

    func run(
        params: Command,
        commandConfig: Config,
        sharedConfig: SharedConfig
    ) throws
}

public struct SharedConfigData {
    public let values: SharedConfigValues
    public let paths: PathsFactoring

    public init(
        values: SharedConfigValues,
        paths: PathsFactoring
    ) {
        self.values = values
        self.paths = paths
    }
}

private extension CommandRunnerProtocol {
    private var logger: Logging {
        DependenciesFactory.resolve()
    }

    private func initializeDependencies(commons: CommonOptions) {
        DependenciesFactory.registerLoggerProducer(commons: commons)
        DependenciesFactory.registerProducers()
    }

    private func logIntentions(command: Command, sharedConfigOptions: SharedConfigOptions?) {
        let message = "Going to run Swiftlane command"
        guard let command = command as? ParsableCommand else {
            return
        }
        logger.important("\(message) \(type(of: command)._commandName.quoted)...".bold)
    }

    private func parseSharedConfig(
        sharedConfigOptions: SharedConfigOptions,
        commandConfigPath: AbsolutePath?
    ) throws -> SharedConfigData {
        let filesManager: FSManaging = DependenciesFactory.resolve()

        let sharedConfigReader = SharedConfigReader(logger: logger, filesManager: filesManager)
        let sharedConfig: SharedConfigModel = try sharedConfigReader.read(
            sharedConfigPath: sharedConfigOptions.sharedConfigPath,
            overridesFrom: commandConfigPath
        )

        let paths = PathsFactory(
            pathsConfig: sharedConfig.pathsConfig,
            projectDir: sharedConfigOptions.projectDir,
            logger: logger
        )

        return SharedConfigData(values: sharedConfig.sharedValues, paths: paths)
    }
}

// MARK: - Public

public extension CommandRunnerProtocol where Config: Decodable, SharedConfig == SharedConfigData {
    /// Run a command with command-specific config and shared config.
    func run(
        _ command: Command,
        sharedConfigOptions: SharedConfigOptions,
        commandConfigPath: AbsolutePath
    ) {
        initializeDependencies(commons: sharedConfigOptions.commonOptions)

        logIntentions(command: command, sharedConfigOptions: sharedConfigOptions)

        CommonRunner(logger: logger).run {
            let filesManager = FSManager(logger: logger, fileManager: FileManager.default)

            let commandConfig: Self.Config = try filesManager.decode(
                commandConfigPath,
                decoder: YAMLDecoder()
            )

            let sharedData = try parseSharedConfig(
                sharedConfigOptions: sharedConfigOptions,
                commandConfigPath: commandConfigPath
            )
            
            try run(
                params: command,
                commandConfig: commandConfig,
                sharedConfig: sharedData
            )
        }
    }
}

public extension CommandRunnerProtocol where Config == Void, SharedConfig == SharedConfigData {
    /// Run a command with shared config.
    func run(
        _ command: Command,
        sharedConfigOptions: SharedConfigOptions
    ) {
        initializeDependencies(commons: sharedConfigOptions.commonOptions)

        logIntentions(command: command, sharedConfigOptions: sharedConfigOptions)

        CommonRunner(logger: logger).run {
            let sharedData = try parseSharedConfig(
                sharedConfigOptions: sharedConfigOptions,
                commandConfigPath: nil
            )

            try run(
                params: command,
                commandConfig: (),
                sharedConfig: sharedData
            )
        }
    }
}

public extension CommandRunnerProtocol where Config: Decodable, SharedConfig == Void {
    /// Run a command without shared config.
    func run(
        _ command: Command,
        commandConfigPath: AbsolutePath,
        commonOptions: CommonOptions
    ) {
        initializeDependencies(commons: commonOptions)

        logIntentions(command: command, sharedConfigOptions: nil)

        CommonRunner(logger: logger).run {
            let filesManager = FSManager(logger: logger, fileManager: FileManager.default)

            let commandConfig: Self.Config = try filesManager.decode(
                commandConfigPath,
                decoder: YAMLDecoder()
            )

            try run(
                params: command,
                commandConfig: commandConfig,
                sharedConfig: ()
            )
        }
    }
}

public extension CommandRunnerProtocol where Config == Void, SharedConfig == Void {
    /// Run a command without any parsable configs.
    func run(
        _ command: Command,
        commonOptions: CommonOptions
    ) {
        initializeDependencies(commons: commonOptions)

        logIntentions(command: command, sharedConfigOptions: nil)

        CommonRunner(logger: logger).run {
            try run(
                params: command,
                commandConfig: (),
                sharedConfig: ()
            )
        }
    }
}
