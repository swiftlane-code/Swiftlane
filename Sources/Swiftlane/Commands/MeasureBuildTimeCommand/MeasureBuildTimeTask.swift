//

import Foundation

import Simulator
import SwiftlaneCore
import Xcodebuild

public final class MeasureBuildTimeTask {
    public struct Config {
        public let deviceModel: String
        public let osVersion: String
        public let iterations: Int
        public let buildForTesting: Bool

        init(
            deviceModel: String,
            osVersion: String,
            iterations: Int,
            buildForTesting: Bool
        ) {
            self.deviceModel = deviceModel
            self.osVersion = osVersion
            self.iterations = iterations
            self.buildForTesting = buildForTesting
        }
    }

    private let simulatorProvider: SimulatorProviding
    private let logger: Logging
    private let shell: ShellExecuting
    private let logPathFactory: LogPathFactoring
    private let builder: BuilderProtocol
    private let config: Config

    public init(
        simulatorProvider: SimulatorProviding,
        logger: Logging,
        shell: ShellExecuting,
        logPathFactory: LogPathFactoring,
        builder: BuilderProtocol,
        config: Config
    ) {
        self.simulatorProvider = simulatorProvider
        self.logger = logger
        self.shell = shell
        self.logPathFactory = logPathFactory
        self.builder = builder
        self.config = config
    }

    public func run() throws {
        let elapsedLogger = TimeMeasurer(logger: logger)

        let destinationSimulator = try simulatorProvider.getAllDevices().first {
            $0.device.name == config.deviceModel && $0.runtime.version == config.osVersion
        }.unwrap()

        // MARK: ====

        var measures = [DateComponents]()

        for i in 1 ... config.iterations {
            builder.cleanDerivedData()

            let start = Date()

            try elapsedLogger.measure(description: "Building iteration \(i)/\(config.iterations)") {
                try builder.build(
                    forTesting: config.buildForTesting,
                    destination: .simulator(destinationSimulator)
                )
            }

            let difference = Calendar.current.dateComponents([.second], from: start, to: Date())
            measures.append(difference)
        }

        let iterationsSeconds = measures.map { $0.second! }
        let totalTime = iterationsSeconds.reduce(0, +)
        let averageTime = totalTime / config.iterations

        iterationsSeconds.enumerated().forEach { idx, seconds in
            logger.warn("Iteration \(idx + 1) took \(seconds) seconds.")
        }

        logger.important([
            "Building", builder.config.scheme,
            builder.config.configuration.map { "(\($0))" } as Any?,
            config.buildForTesting ? "for testing" : "for running",
            config.iterations, "times",
            "took", totalTime, "seconds.",
            "Average:", averageTime, "seconds.",
        ]
        .compactMap { $0 }
        .map { "\($0)" }
        .joined(separator: " ")
        )
    }
}
