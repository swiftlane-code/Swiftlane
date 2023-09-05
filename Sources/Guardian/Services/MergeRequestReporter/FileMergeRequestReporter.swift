//

import Foundation
import SwiftlaneCore

public extension FileMergeRequestReporter {
    /// Create new `FileMergeRequestReporter` instance.
    convenience init(
        logger: Logging,
        filesManager: FSManaging,
        reportFilePath: AbsolutePath
    ) {
        self.init(
            logger: logger,
            filesManager: filesManager,
            reportFactory: MergeRequestReportFactory(
                captionProvider: MergeRequestReportCaptionProvider(ciToolName: "Swiftlane")
            ),
            reportFilePath: reportFilePath
        )
    }
}

public class FileMergeRequestReporter: MergeRequestReporting {
    public enum Errors: Error, Equatable {
        case failsReported(reportURL: String)
    }

    private let logger: Logging
    private let filesManager: FSManaging
    private let reportFactory: MergeRequestReportFactoring
    private let reportFilePath: AbsolutePath

    private var fails: [String] = []
    private var warns: [String] = []
    private var messages: [String] = []
    private var markdowns: [String] = []
    private var successes: [String] = []

    private var isEmptyReport: Bool {
        [fails, warns, messages, markdowns, successes].allSatisfy(\.isEmpty)
    }

    /// Create new `FileMergeRequestReporter` instance.
    public init(
        logger: Logging,
        filesManager: FSManaging,
        reportFactory: MergeRequestReportFactoring,
        reportFilePath: AbsolutePath
    ) {
        self.logger = logger
        self.filesManager = filesManager
        self.reportFactory = reportFactory
        self.reportFilePath = reportFilePath
    }

    public func hasFails() -> Bool {
        !fails.isEmpty
    }

    public func createOrUpdateReport() throws {
        let text = reportFactory.reportBody(
            fails: fails,
            warns: warns,
            messages: messages,
            markdowns: markdowns,
            successes: successes,
            invisibleMark: "invisibleMergeRequestNoteMark",
            commitSHA: "fakeCommitSHA"
        )

        logger.verbose("Guardian report: \n" + text.addPrefixToAllLines("\t"))

        try filesManager.write(reportFilePath, text: text)

        if hasFails() {
            let guardianError = Errors.failsReported(reportURL: reportFilePath.string)
            logger.logError(guardianError)
            throw guardianError
        } else {
            logger.success("Reported no fails, report url: \(reportFilePath.string)")
        }
    }

    public func warn(_ markdown: String) {
        warns.append(markdown)
    }

    public func fail(_ markdown: String) {
        fails.append(markdown)
    }

    public func message(_ markdown: String) {
        messages.append(markdown)
    }

    public func markdown(_ markdown: String) {
        markdowns.append(markdown)
    }

    public func success(_ markdown: String) {
        successes.append(markdown)
    }
}
