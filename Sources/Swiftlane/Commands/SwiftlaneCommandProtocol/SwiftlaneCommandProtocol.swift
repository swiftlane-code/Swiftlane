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
        sharedConfig: SharedConfig,
        logger: Logging
    ) throws

    func verifyConfigs(
        params: Command,
        commandConfig: Config,
        sharedConfig: SharedConfig,
        logger: Logging
    ) throws -> Bool
}

public extension CommandRunnerProtocol {
    func verifyConfigs(
        params _: Command,
        commandConfig _: Config,
        sharedConfig _: SharedConfig,
        logger: Logging
    ) throws -> Bool {
        logger.warn("Custom configs verification is not implemented for this command.")
        return true
    }
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
        DependencyResolver.shared.resolve(Logging.self, .shared)
    }

    private func initializeLoggers(commons: CommonOptions) {
        DependenciesFactory.registerLoggerProducer(commons: commons)
        DependenciesFactory.registerProducers()
    }

    private func logIntentions(command: Command, sharedConfigOptions: SharedConfigOptions?) {
        let message = (sharedConfigOptions?.commonOptions.onlyVerifyConfigs == true)
            ? "Going to verify configs for Swiftlane command"
            : "Going to run Swiftlane command"

        log(command: command, message: message)
    }

    private func log(command: Command, message: String) {
        guard let command = command as? ParsableCommand else {
            return
        }
        logger.important("\(message) \(type(of: command)._commandName.quoted)...".bold)
    }

    private func isAvailableProject(sharedConfig: SharedConfigValues) throws -> Bool {
        let environmentValueReader = EnvironmentValueReader()
        let gitlabCIEnvironmentReader = GitLabCIEnvironmentReader(environmentValueReading: environmentValueReader)
        let projectPath = try gitlabCIEnvironmentReader.string(.CI_PROJECT_PATH)
        guard sharedConfig.availableProjects.isMatching(string: projectPath) else {
            logger.warn("Skipped run task about project with path \(projectPath.quoted)")
            return false
        }
        return true
    }

    private func runOrVerifyConfigs(
        command: Command,
        commandConfig: Config,
        sharedConfig: SharedConfig,
        onlyVerifyConfigs: Bool
    ) throws {
        if onlyVerifyConfigs {
            log(command: command, message: "Verifying configs for Swiftlane command")
            guard try verifyConfigs(
                params: command,
                commandConfig: commandConfig,
                sharedConfig: sharedConfig,
                logger: logger
            ) else {
                Exitor().exit(with: 1)
                return
            }
            logger.success("Configs verified")
            return
        }

        log(command: command, message: "Running Swiftlane command")
        try run(
            params: command,
            commandConfig: commandConfig,
            sharedConfig: sharedConfig,
            logger: logger
        )
    }

    private func parseSharedConfig(
        sharedConfigOptions: SharedConfigOptions,
        commandConfigPath: AbsolutePath?
    ) throws -> SharedConfigData {
        let filesManager = FSManager(logger: logger, fileManager: FileManager.default)

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
        initializeLoggers(commons: sharedConfigOptions.commonOptions)

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

            try runOrVerifyConfigs(
                command: command,
                commandConfig: commandConfig,
                sharedConfig: sharedData,
                onlyVerifyConfigs: sharedConfigOptions.commonOptions.onlyVerifyConfigs
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
        initializeLoggers(commons: sharedConfigOptions.commonOptions)

        logIntentions(command: command, sharedConfigOptions: sharedConfigOptions)

        CommonRunner(logger: logger).run {
            let sharedData = try parseSharedConfig(
                sharedConfigOptions: sharedConfigOptions,
                commandConfigPath: nil
            )

            try runOrVerifyConfigs(
                command: command,
                commandConfig: (),
                sharedConfig: sharedData,
                onlyVerifyConfigs: sharedConfigOptions.commonOptions.onlyVerifyConfigs
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
        initializeLoggers(commons: commonOptions)

        logIntentions(command: command, sharedConfigOptions: nil)

        CommonRunner(logger: logger).run {
            let filesManager = FSManager(logger: logger, fileManager: FileManager.default)

            let commandConfig: Self.Config = try filesManager.decode(
                commandConfigPath,
                decoder: YAMLDecoder()
            )

            try runOrVerifyConfigs(
                command: command,
                commandConfig: commandConfig,
                sharedConfig: (),
                onlyVerifyConfigs: commonOptions.onlyVerifyConfigs
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
        initializeLoggers(commons: commonOptions)

        logIntentions(command: command, sharedConfigOptions: nil)

        CommonRunner(logger: logger).run {
            try runOrVerifyConfigs(
                command: command,
                commandConfig: (),
                sharedConfig: (),
                onlyVerifyConfigs: commonOptions.onlyVerifyConfigs
            )
        }
    }
}
