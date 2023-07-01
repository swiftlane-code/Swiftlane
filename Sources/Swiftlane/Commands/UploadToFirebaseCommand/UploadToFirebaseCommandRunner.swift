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
        sharedConfig _: SharedConfigValues
    ) throws -> String {
        if let notes = params.releaseNotes {
            return notes
        }

        let changelogFactory = ChangelogFactory(
            logger: DependenciesFactory.resolve(),
            gitlabCIEnvironmentReader: DependenciesFactory.resolve(),
            jiraClient: DependenciesFactory.resolve(),
            issueKeySearcher: DependenciesFactory.resolve()
        )

        return try changelogFactory.changelog()
    }

    private func uploadIPA(
        params: UploadToFirebaseCommandParamsAccessing,
        releaseNotes: String
    ) throws {
        let googleAuthClient = GoogleAuthAPIClient(
            refreshToken: params.firebaseToken.sensitiveValue,
            logger: DependenciesFactory.resolve()
        )

        let firebaseDistributionClient = try FirebaseDistributionAPIClient(
            firebaseAppID: params.firebaseAppID,
            logger: DependenciesFactory.resolve()
        )

        let ipaUploader = FirebaseDistributionIPAUploader(
            logger: DependenciesFactory.resolve(),
            timeMeasurer: DependenciesFactory.resolve(),
            googleAuthClient: googleAuthClient,
            appDistributionClient: firebaseDistributionClient
        )

        let testersEmails = params.testersEmails.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let testersGroupsAliases = params.testersGroupsAliases.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let filesManager: FSManaging = DependenciesFactory.resolve()
        
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
        sharedConfig: SharedConfigData
    ) throws {
        let releaseNotes = try releaseNotes(
            params: params,
            sharedConfig: sharedConfig.values
        )

        try uploadIPA(
            params: params,
            releaseNotes: releaseNotes
        )
    }
}
