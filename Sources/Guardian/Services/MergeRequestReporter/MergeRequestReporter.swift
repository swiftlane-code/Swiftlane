//

import Foundation
import GitLabAPI
import SwiftlaneCore

// sourcery: AutoMockable
public protocol MergeRequestReporting {
    func checkEnvironmentCorrect() throws

    func createOrUpdateReport() throws

    func warn(_ markdown: String)

    func fail(_ markdown: String)

    func message(_ markdown: String)

    func markdown(_ markdown: String)

    func success(_ markdown: String)

    func hasFails() -> Bool
}

public extension MergeRequestReporter {
    /// Create new `MergeRequestReporter` instance.
    ///
    /// - Parameters:
    ///   - publishEmptyReport: when `false` empty report will not be commented/updated.
    convenience init(
        logger: Logging,
        gitlabApi: GitLabAPIClientProtocol,
        gitlabCIEnvironment: GitLabCIEnvironmentReading,
        publishEmptyReport: Bool
    ) {
        self.init(
            logger: logger,
            gitlabApi: gitlabApi,
            gitlabCIEnvironment: gitlabCIEnvironment,
            reportFactory: MergeRequestReportFactory(
                captionProvider: MergeRequestReportCaptionProvider(ciToolName: "Swiftlane")
            ),
            publishEmptyReport: publishEmptyReport,
            commentIdentificator: "swiftlane"
        )
    }
}

public class MergeRequestReporter: MergeRequestReporting {
    public enum Errors: Error, Equatable {
        case failsReported(reportURL: String)
    }

    private let logger: Logging
    private let gitlabApi: GitLabAPIClientProtocol
    private let gitlabCIEnvironment: GitLabCIEnvironmentReading
    private let reportFactory: MergeRequestReportFactoring

    private var fails: [String] = []
    private var warns: [String] = []
    private var messages: [String] = []
    private var markdowns: [String] = []
    private var successes: [String] = []

    private var isEmptyReport: Bool {
        [fails, warns, messages, markdowns, successes].allSatisfy(\.isEmpty)
    }

    private let publishEmptyReport: Bool

    /// Existing merge request comment which contains this mark will be edited.
    private let invisibleMergeRequestNoteMark: String

    /// Create new `MergeRequestReporter` instance.
    ///
    /// - Parameters:
    ///   - publishEmptyReport: when `false` empty report will not be commented/updated.
    ///   - commentIdentificator: invisible identifier of merge request comment
    ///   	which is used to determine which existing comment can be updated instead of creating a new one.
    public init(
        logger: Logging,
        gitlabApi: GitLabAPIClientProtocol,
        gitlabCIEnvironment: GitLabCIEnvironmentReading,
        reportFactory: MergeRequestReportFactoring,
        publishEmptyReport: Bool,
        commentIdentificator: String = "swiftlane-managed"
    ) {
        self.logger = logger
        self.gitlabApi = gitlabApi
        self.gitlabCIEnvironment = gitlabCIEnvironment
        self.reportFactory = reportFactory
        invisibleMergeRequestNoteMark = "<!-- " + commentIdentificator + " -->" // invisible markdown comment syntax.
        self.publishEmptyReport = publishEmptyReport
    }

    public func hasFails() -> Bool {
        !fails.isEmpty
    }

    private func readEnvironment() throws -> (
        projectURL: String,
        projectId: Int,
        mergeRequestIid: Int,
        commitSHA: String
    ) {
        (
            projectURL: try gitlabCIEnvironment.string(.CI_PROJECT_URL),
            projectId: try gitlabCIEnvironment.int(.CI_PROJECT_ID),
            mergeRequestIid: try gitlabCIEnvironment.int(.CI_MERGE_REQUEST_IID),
            commitSHA: try gitlabCIEnvironment.string(.CI_COMMIT_SHA)
        )
    }

    public func checkEnvironmentCorrect() throws {
        let _ = try readEnvironment()
    }

    public func createOrUpdateReport() throws {
        let (projectURL, projectId, mergeRequestIid, commitSHA) = try readEnvironment()

        guard publishEmptyReport || !isEmptyReport else {
            logger.important("Guardian report is empty. It will not be created/updated in merge request.")
            return
        }

        let text = reportFactory.reportBody(
            fails: fails,
            warns: warns,
            messages: messages,
            markdowns: markdowns,
            successes: successes,
            invisibleMark: invisibleMergeRequestNoteMark,
            commitSHA: commitSHA
        )

        logger.verbose("Guardian report: \n" + text.addPrefixToAllLines("\t"))

        let notes = try gitlabApi.mergeRequestNotes(
            projectId: projectId,
            mergeRequestIid: mergeRequestIid,
            orderBy: .createdAt,
            sorting: .descending
        ).await()

        let reportNote: MergeRequest.Note

        if let notedId = notes.first(where: { $0.body.contains(invisibleMergeRequestNoteMark) })?.id {
            reportNote = try gitlabApi.setMergeRequestNote(
                projectId: projectId,
                mergeRequestIid: mergeRequestIid,
                noteId: notedId,
                body: text
            ).await()
        } else {
            reportNote = try gitlabApi.createMergeRequestNote(
                projectId: projectId,
                mergeRequestIid: mergeRequestIid,
                body: text
            ).await()
        }

        let reportURL = projectURL + "/-/merge_requests/\(mergeRequestIid)#note_\(reportNote.id)"
        if hasFails() {
            let guardianError = Errors.failsReported(reportURL: reportURL)
            logger.logError(guardianError)
            throw guardianError
        } else {
            logger.success("Reported no fails, report url: \(reportURL)")
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
