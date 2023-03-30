
import Foundation
import Guardian
import SwiftlaneCore

public extension CheckStopListTask {
    struct StopListConfig: Decodable {
        public let files: FilesChecker.Files
        public let contents: [ContentChecker.Content]
    }
}

public extension CheckStopListTask {
    struct Config {
        let stopListConfig: StopListConfig
    }
}

public extension CheckStopListTask {
    enum Errors: Error {
        case foundedFilesFromStopList
    }
}

public final class CheckStopListTask {
    private let config: Config

    private let reporter: MergeRequestReporting
    private let filesChecker: FilesChecking
    private let contentsChecker: ContentChecking

    private var configFiles: FilesChecker.Files { config.stopListConfig.files }
    private var configContents: [ContentChecker.Content] { config.stopListConfig.contents }

    public init(
        config: Config,
        reporter: MergeRequestReporting,
        filesChecker: FilesChecking,
        contentsChecker: ContentChecking
    ) {
        self.config = config
        self.reporter = reporter
        self.filesChecker = filesChecker
        self.contentsChecker = contentsChecker
    }

    private func checkStopListFiles() throws {
        let stopList = configFiles.gitignoreFiles + configFiles.otherFiles + configFiles.stopList
        try filesChecker.checkStopListFiles(stopList: stopList)
    }

    private func checkStopListContents(projectDir: AbsolutePath) throws {
        try contentsChecker.checkTabsInChangedFiles(projectDir: projectDir, contents: configContents)
    }

    public func run(
        projectDir: AbsolutePath
    ) throws {
        try checkStopListFiles()
        try checkStopListContents(projectDir: projectDir)

        try reporter.createOrUpdateReport()
    }
}
