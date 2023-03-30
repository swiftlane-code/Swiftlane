//

import ArgumentParser
import Foundation

/// Root CLI command to provide info about Swiftlane and list all available commands.
public struct SwiftlaneRootCommand: ParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "Swiftlane",
        abstract: "A utility for running CI tasks.",
        version: UTILL_VERSION,
        subcommands: [
            RunTestsCommand.self,
            GuardianBeforeBuildCommand.self,
            GuardianAfterBuildCommand.self,
            GuardianInitialNoteCommand.self,
            GuardianCheckAuthorCommand.self,
            //			SetupIssueFixVersionsCommand.self,
            MeasureBuildTimeCommand.self,
            //			NotifyFailedJobCommand.self,
            PatchTestPlanEnvCommand.self,
            //			ChangeJiraIssueStatusCommand.self,
            ChangeJiraIssueLabelsCommand.self,
            CheckCommitsCommand.self,
            SetupReviewersCommand.self,
            SetupAssigneeCommand.self,
            CheckStopListCommand.self,
            UploadToFirebaseCommand.self,
            UploadToAppStoreCommand.self,
            SetupLabelsCommand.self,
            CertsCommand.self,
            BuildAppCommand.self,
            SetProvisioningCommand.self,
            //			ChangeJiraIssueBuildNumberCommand.self,
            //			ChangeJiraIssueFixVersionCommand.self,
            ArchiveAndExportIPACommand.self,
            //			MakeBuildNumberCommand.self,
            //			CutReleaseCommand.self,
            AddJiraIssueCommentCommand.self,
            ReportUnusedCodeCommand.self,
            UploadGitLabPackageCommand.self,
            //			SyncDSYMsCommand.self,
            //			CleanupDSYMsCommand.self,
            ChangeVersionCommand.self,
            PingCommand.self,
            BuildNumberCommand.self,
        ]
    )

    public init() {}
}
