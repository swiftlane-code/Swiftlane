//

import AppStoreConnectAPI
import Foundation
import Git
import GitLabAPI
import Guardian
import JiraAPI
import Networking
import Provisioning
import Simulator
import SwiftlaneCore
import Xcodebuild

public enum DependenciesFactory {
    public static func resolve<T>(
        _ strategy: DependencyResolver.Strategy = .shared,
        requiredType: T.Type = T.self
    ) -> T {
        DependencyResolver.shared.resolve(requiredType, strategy)
    }

    public static var logger: Logging {
        resolve(.shared)
    }

    public static func registerLoggerProducer(commons: CommonOptions) {
        let logLevel = LoggingLevel(from: commons.resolvedLogLevel)
        let mainLogger: Logging
        if logLevel >= .info {
            mainLogger = DetailedLogger(logLevel: logLevel)
        } else {
            mainLogger = SimpleLogger(logLevel: logLevel)
        }

        guard let verboseLogFile = commons.verboseLogfile else {
            DependencyResolver.shared.register(Logging.self) {
                mainLogger
            }
            return
        }

        do {
            let filesManager = FSManager(logger: mainLogger, fileManager: FileManager.default)
            var file = try FileHandleTextOutputStream(
                filesManager: filesManager,
                filePath: verboseLogFile,
                appendFile: true
            )

            let fileLogger = DetailedLogger(logLevel: .verbose) {
                Swift.print($0, terminator: $1, to: &file)
            }

            let compositeLogger = CompositeLogger(loggers: [mainLogger, fileLogger])

            DependencyResolver.shared.register(Logging.self) {
                compositeLogger
            }
        } catch {
            mainLogger.logError(error)
            Exitor().exit(with: 1)
        }
    }

    public static func registerProducers() {
        DependencyResolver.shared.register(XcodeChecking.self) {
            XcodeChecker()
        }

        DependencyResolver.shared.register(FSManaging.self) {
            FSManager(
                logger: resolve(.shared),
                fileManager: FileManager.default
            )
        }

        DependencyResolver.shared.register(ShellExecuting.self) {
            ShellExecutor(
                sigIntHandler: resolve(.shared),
                logger: resolve(.shared),
                xcodeChecker: resolve(.shared),
                filesManager: resolve(.shared)
            )
        }

        DependencyResolver.shared.register(SigIntHandling.self) {
            SigIntHandler(logger: resolve(.shared))
        }

        DependencyResolver.shared.register(RuntimesMining.self) {
            RuntimesMiner(shell: resolve(.shared))
        }

        DependencyResolver.shared.register(SimulatorProviding.self) {
            SimulatorProvider(
                runtimesMiner: resolve(.shared),
                shell: resolve(.shared),
                logger: resolve(.shared)
            )
        }

        DependencyResolver.shared.register(Exiting.self) {
            Exitor()
        }

        DependencyResolver.shared.register(EnvironmentValueReading.self) {
            EnvironmentValueReader()
        }

        DependencyResolver.shared.register(GitLabCIEnvironmentReading.self) {
            GitLabCIEnvironmentReader(environmentValueReading: resolve(.shared))
        }

        DependencyResolver.shared.register(GitProtocol.self) {
            Git(
                shell: resolve(.shared),
                filesManager: resolve(.shared),
                diffParser: GitDiffParser(logger: resolve(.shared))
            )
        }

        DependencyResolver.shared.register(GitLabAPIClientProtocol.self) {
            // TODO: force unwrap
            try! GitLabAPIClient(logger: resolve(.shared))
        }

        DependencyResolver.shared.register(MergeRequestReporting.self) {
            //			GitLabMergeRequestReporter(
            //				logger: logger,
            //				gitlabApi: resolve(.shared),
            //				gitlabCIEnvironment: resolve(.shared),
            //				reportFactory: MergeRequestReportFactory(),
            //				publishEmptyReport: true
            //			)
            FileMergeRequestReporter(
                logger: resolve(.shared),
                filesManager: resolve(.shared),
                reportFilePath: try! AbsolutePath(FileManager.default.currentDirectoryPath + "/report.md")
            )
        }

        DependencyResolver.shared.register(XCCOVServicing.self) {
            XCCOVService(
                filesManager: resolve(.shared),
                shell: resolve(.shared)
            )
        }

        DependencyResolver.shared.register(TargetCoverageReporting.self) {
            TargetCoverageReporter(reporter: resolve())
        }

        DependencyResolver.shared.register(TargetsCoverageTargetsFiltering.self) {
            TargetsCoverageTargetsFilterer()
        }

        DependencyResolver.shared.register(SlatherServicing.self) {
            SlatherService(filesManager: resolve())
        }

        DependencyResolver.shared.register(ChangesCoverageReporting.self) {
            ChangesCoverageReporter(reporter: resolve())
        }

        DependencyResolver.shared.register(XCLogParserServicing.self) {
            XCLogParserService(filesManager: resolve(), shell: resolve())
        }

        DependencyResolver.shared.register(XCLogParserIssueFormatting.self) {
            XCLogParserIssueMarkdownFormatter()
        }

        DependencyResolver.shared.register(BuildErrorsReporting.self) {
            BuildErrorsReporter(
                reporter: resolve(),
                issueFormatter: resolve()
            )
        }

        DependencyResolver.shared.register(UnitTestsResultsReporting.self) {
            UnitTestsResultsReporter(reporter: resolve(.shared))
        }

        DependencyResolver.shared.register(JUnitServicing.self) {
            JUnitService(filesManager: resolve(.shared))
        }

        DependencyResolver.shared.register(FilesCheckerReporting.self) {
            FilesCheckerEnReporter(reporter: resolve(.shared))
        }

        DependencyResolver.shared.register(FilesChecking.self) {
            FilesChecker(
                logger: resolve(.shared),
                gitlabCIEnvironment: resolve(.shared),
                gitlabApi: resolve(.shared),
                reporter: resolve(.shared)
            )
        }

        DependencyResolver.shared.register(ContentCheckerReporting.self) {
            ContentCheckerEnReporter(
                reporter: resolve(.shared),
                rangesWelder: resolve(.shared)
            )
        }

        DependencyResolver.shared.register(RangesWelding.self) {
            RangesWelder()
        }

        DependencyResolver.shared.register(ContentChecking.self) {
            ContentChecker(
                logger: resolve(.shared),
                filesManager: resolve(.shared),
                git: resolve(.shared),
                reporter: resolve(.shared)
            )
        }

        DependencyResolver.shared.register(LogPathFactoring.self) {
            LogPathFactory(filesManager: resolve())
        }

        DependencyResolver.shared.register(XcodebuildCommandProducing.self) {
            XcodebuildCommandProducer(isUseRosetta: false)
        }

        DependencyResolver.shared.register(TimeMeasuring.self) {
            TimeMeasurer(logger: resolve())
        }

        DependencyResolver.shared.register(XCArchiveExporting.self) {
            XCArchiveExporter(
                logger: resolve(),
                shell: resolve(),
                filesManager: resolve(),
                timeMeasurer: resolve(),
                xcodebuildCommand: resolve()
            )
        }

        DependencyResolver.shared.register(XCArchiveDSYMsExtracting.self) {
            XCArchiveDSYMsExtractor(
                logger: resolve(),
                shell: resolve(),
                filesManager: resolve(),
                timeMeasurer: resolve()
            )
        }

        DependencyResolver.shared.register(ProvisioningProfilesServicing.self) {
            ProvisioningProfilesService(
                filesManager: resolve(),
                logger: resolve(),
                provisionProfileParser: resolve()
            )
        }

        DependencyResolver.shared.register(MobileProvisionParsing.self) {
            MobileProvisionParser(logger: resolve(), shell: resolve())
        }

        DependencyResolver.shared.register(XcodeProjectPatching.self) {
            XcodeProjectPatcher(
                logger: resolve(),
                shell: resolve(),
                plistBuddyService: resolve()
            )
        }

        DependencyResolver.shared.register(PlistBuddyServicing.self) {
            PlistBuddyService(shell: resolve())
        }

        DependencyResolver.shared.register(OpenSSLServicing.self) {
            OpenSSLService(shell: resolve(), filesManager: resolve())
        }

        DependencyResolver.shared.register(MacOSSecurityProtocol.self) {
            MacOSSecurity(shell: resolve())
        }

        DependencyResolver.shared.register(RemoteCertificateInstalling.self) {
            RemoteCertificateInstaller(
                logger: resolve(),
                shell: resolve(),
                filesManager: resolve(),
                security: resolve(),
                urlSession: URLSession.shared
            )
        }

        DependencyResolver.shared.register(CertsAtomicInstalling.self) {
            CertsAtomicInstaller(
                logger: resolve(),
                filesManager: resolve(),
                openssl: resolve(),
                security: resolve(),
                provisioningProfileService: resolve()
            )
        }

        DependencyResolver.shared.register(CertsInstalling.self) {
            CertsInstaller(
                logger: resolve(),
                repo: resolve(), // problem
                atomicInstaller: resolve(),
                filesManager: resolve(),
                remoteCertInstaller: resolve()
            )
        }

        DependencyResolver.shared.register(CertsRepositoryProtocol.self) {
            CertsRepository(
                git: resolve(),
                openssl: resolve(),
                filesManager: resolve(),
                provisioningProfileService: resolve(),
                provisionProfileParser: resolve(),
                security: resolve(),
                logger: resolve(),
                config: resolve()
            )
        }

        DependencyResolver.shared.register(CertsRepository.Config.self) {
            CertsRepository.Config(
                gitAuthorName: nil,
                gitAuthorEmail: nil
            )
        }

        DependencyResolver.shared.register(IssueKeySearching.self) {
            IssueKeySearcher(
                logger: resolve(),
                issueKeyParser: resolve(),
                gitlabCIEnvironmentReader: resolve()
            )
        }

        DependencyResolver.shared.register(IssueKeyParsing.self) {
            IssueKeyParser(jiraProjectKey: "[A-Z]{3,}")
        }

        DependencyResolver.shared.register(JiraAPIClientProtocol.self) {
            // TODO: force unwrap
            try! JiraAPIClient(
                requestsTimeout: 60, // TODO: hardcode
                logger: resolve()
            )
        }

        DependencyResolver.shared.register(PasswordReading.self) {
            PasswordReader()
        }

        DependencyResolver.shared.register(AppStoreConnectAuthKeyIDParsing.self) {
            AppStoreConnectAuthKeyIDParser()
        }

        DependencyResolver.shared.register(ProjectVersionConverting.self) {
            StraightforwardProjectVersionConverter()
        }

        DependencyResolver.shared.register(SwiftLintProtocol.self) {
            SwiftLint(
                shell: resolve(),
                swiftlintPath: "swiftlint"
            )
        }

        DependencyResolver.shared.register(WarningLimitsCheckerReporting.self) {
            WarningLimitsCheckerEnReporter(reporter: resolve())
        }

        DependencyResolver.shared.register(ExpiringToDoSorting.self) {
            ExpiringToDoSorter()
        }

        DependencyResolver.shared.register(ExpiringToDoParsing.self) {
            ExpiringToDoParser()
        }

        DependencyResolver.shared.register(SwiftCodeParsing.self) {
            // TODO: force unwrap
            try! SwiftCodeParser(
                logger: resolve(),
                filesManager: resolve()
            )
        }

        DependencyResolver.shared.register(FilePathReporting.self) {
            FilePathReporter(reporter: resolve())
        }

        DependencyResolver.shared.register(XCTestPlanPatching.self) {
            XCTestPlanPatcher(
                logger: resolve(),
                filesManager: resolve(),
                environmentReader: resolve()
            )
        }

        DependencyResolver.shared.register(PeripheryServicing.self) {
            PeripheryService(
                shell: resolve(),
                filesManager: resolve()
            )
        }

        DependencyResolver.shared.register(PeripheryResultsFormatting.self) {
            PeripheryResultsMarkdownFormatter(filesManager: resolve())
        }

        DependencyResolver.shared.register(ProgressLogging.self) {
            ProgressLogger(winsizeReader: resolve())
        }

        DependencyResolver.shared.register(NetworkingProgressLogging.self) {
            NetworkingProgressLogger(progressLogger: resolve())
        }
    }
}
