//

import AppStoreConnectAPI
import AppStoreConnectJWT
import FirebaseAPI
import Foundation
import Git
import Guardian
import JiraAPI
import Provisioning
import Simulator
import SwiftlaneCore
import Xcodebuild
import Yams

public class UploadToFirebaseCommandRunner: CommandRunnerProtocol {
    private func releaseNotes(
        params: UploadToFirebaseCommandParamsAccessing,
        sharedConfig: SharedConfigValues,
        logger: Logging
    ) throws -> String {
        if let notes = params.releaseNotes {
            return notes
        }

        let environmentValueReader = EnvironmentValueReader()
        let gitlabCIEnvironmentReader = GitLabCIEnvironmentReader(environmentValueReading: environmentValueReader)

        let changelogFactory = ChangelogFactory(
            logger: logger,
            gitlabCIEnvironmentReader: gitlabCIEnvironmentReader,
            jiraClient: try JiraAPIClient(
                requestsTimeout: sharedConfig.jiraRequestsTimeout,
                logger: logger
            ),
            issueKeySearcher: IssueKeySearcher(
                logger: logger,
                issueKeyParser: IssueKeyParser(jiraProjectKey: sharedConfig.jiraProjectKey),
                gitlabCIEnvironmentReader: gitlabCIEnvironmentReader
            )
        )

        return try changelogFactory.changelog()
    }

    private func uploadIPA(
        params: UploadToFirebaseCommandParamsAccessing,
        releaseNotes: String,
        logger: Logging
    ) throws {
        let timeMeasurer = TimeMeasurer(logger: logger)

        let googleAuthClient = GoogleAuthAPIClient(
            refreshToken: params.firebaseToken.sensitiveValue,
            logger: logger
        )

        let firebaseDistributionClient = try FirebaseDistributionAPIClient(
            firebaseAppID: params.firebaseAppID,
            logger: logger
        )

        let ipaUploader = FirebaseDistributionIPAUploader(
            logger: logger,
            timeMeasurer: timeMeasurer,
            googleAuthClient: googleAuthClient,
            appDistributionClient: firebaseDistributionClient
        )

        let filesManager = FSManager(
            logger: logger,
            fileManager: FileManager.default
        )

        let testersEmails = params.testersEmails.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let testersGroupsAliases = params.testersGroupsAliases.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let ipaData = try filesManager.readData(params.ipaPath, log: true)

        try ipaUploader.uploadRelease(
            fileName: params.ipaPath.lastComponent.string,
            ipaData: ipaData,
            releaseNotes: releaseNotes,
            testersEmails: testersEmails,
            testersGroupsAliases: testersGroupsAliases
        )
    }

    public func run(
        params: UploadToFirebaseCommandParamsAccessing,
        commandConfig _: Void,
        sharedConfig: SharedConfigData,
        logger: Logging
    ) throws {
        let releaseNotes = try releaseNotes(
            params: params,
            sharedConfig: sharedConfig.values,
            logger: logger
        )

        try uploadIPA(
            params: params,
            releaseNotes: releaseNotes,
            logger: logger
        )
    }
}
