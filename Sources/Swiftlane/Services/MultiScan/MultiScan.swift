//

import Combine
import Foundation

import Simulator
import SwiftlaneCore
import Xcodebuild

public enum MultiScanError: Error {
    case buildFailed
    case testsFailed
    case testPlanNotFound
    case testsResultsXCResultPathNotFound
    case testsResultsJUnitPathNotFound
}

// sourcery: AutoMockable
public protocol MultiScanProtocol {}

public class MultiScan: MultiScanProtocol {
    private let filesManager: FSManager
    private let logPathFactory: LogPathFactoring
    private let simulatorProvider: SimulatorProviding
    private let shell: ShellExecuting
    private let logger: Logging
    private let timeMeasurer: TimeMeasuring
    private let testPlanService: XCTestPlanServicing
    private let junitService: JUnitServicing

    public let config: Config
    public let projectDir: AbsolutePath
    public let builder: Builder
    public let runner: TestsRunner

    public init(
        filesManager: FSManager,
        logPathFactory: LogPathFactoring,
        simulatorProvider: SimulatorProviding,
        testPlanService: XCTestPlanServicing,
        junitService: JUnitServicing,
        shell: ShellExecuting,
        logger: Logging,
        timeMeasurer: TimeMeasuring,
        config: Config,
        builder: Builder,
        runner: TestsRunner,
        projectDir: AbsolutePath
    ) {
        self.filesManager = filesManager
        self.logPathFactory = logPathFactory
        self.simulatorProvider = simulatorProvider
        self.testPlanService = testPlanService
        self.junitService = junitService
        self.shell = shell
        self.logger = logger
        self.timeMeasurer = timeMeasurer
        self.config = config
        self.builder = builder
        self.runner = runner
        self.projectDir = projectDir
    }

    public func run() throws -> [TestsRunner.TestRunResult] {
        // shutdown all running sims just in case.
        try? Simulator.shutdownAll(shell: shell)

        defer { try? Simulator.shutdownAll(shell: shell) }

        let simulators = try prepareSimulators(preboot: true, eraseExisting: true)

        try buildTests()

        do {
            let results = try timeMeasurer.measure(description: "Running Tests") {
                try runTests(on: simulators).await(timeout: runner.config.testingTimeout + 100)
            }

            do {
                try mergeResults(for: results)
            } catch {
                // TODO: should we throw this upwards or just ignore?
                logger.warn("Ignored error: \"\(String(reflecting: error))\"")
            }

            results.forEach { result in
                do {
                    try self.collectSystemLogs(runResult: result)
                } catch {
                    // TODO: should we throw this upwards or just ignore?
                    logger.warn("Ignored error: \"\(String(reflecting: error))\"")
                }
            }

            if results.compactMap(\.result.error).isEmpty {
                logger.success("MultiScan: Testing succeeded")
            }

            return results
        } catch {
            throw error
        }
    }

    /// Create required simulators as per config.
    /// - Parameters:
    ///   - preboot: boot all prepared simulators.
    ///   			 When `true` it saves time on waiting for sims to boot up after tests are already built.
    ///   - eraseExisting: if existing simulators should be erased.
    private func prepareSimulators(preboot: Bool, eraseExisting: Bool) throws -> [Simulator] {
        try timeMeasurer.measure(description: "Preparing simulators") {
            let cloner = SimulatorCloner(
                original: config.referenceSimulator,
                simulatorProvider: simulatorProvider,
                timeMeasurer: timeMeasurer
            )
            //			cloner.deleteAllClones()
            let clones = try cloner.makeClones(
                count: config.simulatorsCount,
                preboot: preboot,
                eraseExisting: eraseExisting,
                eraseNewlyCloned: eraseExisting
            )
            clones.forEach {
                try? $0.disableSlideToType()
            }
            return clones
        }
    }

    /// Performs build for testing.
    private func buildTests() throws {
        try builder.resolveSPMDependencies(simulator: config.referenceSimulator)
        try builder.showBuildSettings(simulator: config.referenceSimulator)
        try builder.buildForTesting(simulator: config.referenceSimulator)
    }

    private func runTests(on simulators: [Simulator]) throws -> AnyPublisher<[TestsRunner.TestRunResult], Error> {
        /// # Support running all tests on single simulator.
        /// In this case we don't need to scan for built tests
        /// and instead just pass empty array to `testWithoutBuilding` to run all of the available tests.
        let builtTestsPublisher: AnyPublisher<[XCTestFunction], Error> =
            simulators.count == 1
                ? Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
                : try runner.getBuiltTests()

        let selectedPlan: XCTestPlanInfo? = try config.testsRunnerConfig.testPlan.map {
            try testPlanService.getTestPlan(
                named: $0,
                inDirectory: projectDir
            )
        }

        return builtTestsPublisher
            //			.map { $0.prefix(4).asArray }
            .map { [testPlanService] builtTests -> [XCTestFunction] in
                guard let plan = selectedPlan else {
                    return builtTests
                }

                let result = testPlanService.filter(builtTests: builtTests, using: plan)
                return result
            }
            .flatMap { [unowned self] allTests -> AnyPublisher<[TestsRunner.TestRunResult], Never> in
                if allTests.isEmpty {
                    logger.important("Going to run all availale tests on single simulator.")
                } else {
                    logger.important("Going to run \(allTests.count) tests on \(simulators.count) simulators.")
                }

                let testsChunks = splitTestsIntoChunks(allTests: allTests, chunksCount: simulators.count)

                let publishers = zip(simulators, testsChunks)
                    .map { simulator, chunk in
                        performAsync { [self] in
                            runTests(chunk: chunk, on: simulator, allTestsCount: allTests.count)
                        }
                    }

                return Publishers.MergeMany(publishers)
                    .collect()
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    /// Run specified tests on a given simulator.
    /// - Parameters:
    ///   - allTestsCount: total count of test functions including passed `chunk.count`. Used for logging.
    private func runTests(chunk: [XCTestFunction], on simulator: Simulator, allTestsCount: Int) -> TestsRunner.TestRunResult {
        // swiftformat:disable indent
		if chunk.isEmpty {
			logger.important(
				"Running all available tests on \(simulator.device.name)..."
			)
		} else {
			let testsList = chunk.map(\.name).joined(separator: "\n")
			logger.important(
				"Running \(chunk.count)/\(allTestsCount) tests on \(simulator.device.name)...\n" +
				("Tests list: \n" + testsList)
					.addPrefixToAllLines("\t")
			)
		}
		return timeMeasurer.measure(description: "Running tests on \(simulator.device.name)") {
			self.runner.runTests(simulator: simulator, tests: chunk)
		}
		// swiftformat:enable indent
    }

    /// Split all tests into multiple parts.
    private func splitTestsIntoChunks(allTests: [XCTestFunction], chunksCount: Int) -> [[XCTestFunction]] {
        guard !allTests.isEmpty else {
            return [[]]
        }

        let chunkSize = Int((Double(allTests.count) / Double(chunksCount)).rounded(.up))

        let chunks: [[XCTestFunction]] = stride(from: 0, to: allTests.count, by: chunkSize)
            .map { chunkStart in
                let end = allTests.endIndex
                let chunkEnd = allTests.index(chunkStart, offsetBy: chunkSize, limitedBy: end) ?? end
                return Array(allTests[chunkStart ..< chunkEnd])
            }
        return chunks
    }

    /// Collect `system.log` files of all used simulators into results directory.
    private func collectSystemLogs(runResult: TestsRunner.TestRunResult) throws {
        let targetSystemLogPath = logPathFactory.makeSystemLogPath(
            logsDir: builder.config.logsPath,
            scheme: builder.config.scheme,
            simulatorName: runResult.simulator.device.name
        )

        let logPath = try Path(runResult.simulator.device.logPath).makeAbsoluteIfIsnt(relativeTo: projectDir)
        let systemLog = logPath.appending(path: try! RelativePath("system.log"))

        logger.info("Collecting '\(systemLog)'...")
        try filesManager.copy(systemLog, to: targetSystemLogPath)
    }

    /// Collect all `.junit` and `.xcresult` files into results folder.
    private func mergeResults(for testsResults: [TestsRunner.TestRunResult]) throws {
        let mergedXCResultPath = config.mergedXCResultPath
        let mergedJUnitPath = config.mergedJUnitPath

        if testsResults.count <= 1 {
            guard let result = testsResults.first else {
                logger.error("TestRunResult empty!")
                return
            }

            try copyResults(for: result, mergedXCResultPath: mergedXCResultPath, mergedJUnitPath: mergedJUnitPath)
        } else {
            try merge(xcresults: testsResults.compactMap(\.xcresultPath), to: mergedXCResultPath)
            logger.success("Produced mergedXCResult: \(mergedXCResultPath)")

            try merge(junit: testsResults.compactMap(\.junitPath), to: mergedJUnitPath)
            logger.success("Produced mergedJUnit: \(mergedJUnitPath)")
        }
    }

    /// Merge multiple `.xcresult`s into single one.
    private func merge(xcresults paths: [AbsolutePath], to mergedResultPath: AbsolutePath) throws {
        try shell.run(
            "xcrun xcresulttool merge \(paths.map { "'\($0)'" }.joined(separator: " ")) --output-path '\(mergedResultPath)'",
            log: .silent
        )
    }

    /// Merge multiple `.junit` files into single one.
    private func merge(junit paths: [AbsolutePath], to mergedResultPath: AbsolutePath) throws {
        try junitService.mergeJUnit(filesPaths: paths, into: mergedResultPath)
    }

    /// Copy `.xcresults` and `.junit` from derived data into specified paths.
    private func copyResults(
        for testsResults: TestsRunner.TestRunResult,
        mergedXCResultPath: AbsolutePath,
        mergedJUnitPath: AbsolutePath
    ) throws {
        guard let xcresultPath = testsResults.xcresultPath else { throw MultiScanError.testsResultsXCResultPathNotFound }
        do {
            try filesManager.copy(xcresultPath, to: mergedXCResultPath)
        } catch {
            logger.error("Error copy `.xcresults`: \"\(String(reflecting: error))\"")
        }

        guard let junitPath = testsResults.junitPath else { throw MultiScanError.testsResultsJUnitPathNotFound }
        do {
            try filesManager.copy(junitPath, to: mergedJUnitPath)
        } catch {
            logger.error("Error copy `.junit`: \"\(String(reflecting: error))\"")
        }
    }
}
