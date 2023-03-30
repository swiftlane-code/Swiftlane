//

import Combine
import Foundation
import Networking
import SwiftlaneCore

public protocol FirebaseDistributionIPAUploading {
    /// Uploads .ipa to Firebase App Distribution.
    ///
    /// Steps:
    /// 1) Upload release binary.
    /// 2) Poll upload operation status.
    /// 3) Set release notes.
    /// 4) Distribute to specified testers.
    ///
    /// Note: this is a thread blocking function.
    ///
    /// - Parameters:
    ///   - fileName: name of .ipa file.
    ///   - ipaData: contents of binary file.
    ///   - releaseNotes: release notes.
    ///   - testersEmails: emails of testers.
    ///   - testersGroupsAliases: Firebase testers groups aliases.
    ///   - uploadStatusPollingRetries: max attempts to poll uploaded release status (step 2).
    /// 	Recommended value: `60`.
    ///   - uploadStatusPollingRetryDelay: waiting time before next status polling attempt (step 2).
    /// 	Recommended value: `5`.
    ///   - uploadTimeout: ipa upload request timeout (step 1). Take into account size of your binary.
    ///     Recommended value: `600` (10 minutes) or even more.
    ///   - uploadRetries: max amount of retries of binary upload request (step 1).
    /// 	Recommended value: `1`.
    func uploadRelease(
        fileName: String,
        ipaData: Data,
        releaseNotes: String,
        testersEmails: [String],
        testersGroupsAliases: [String],
        uploadStatusPollingRetries: UInt,
        uploadStatusPollingRetryDelay: TimeInterval,
        uploadTimeout: TimeInterval,
        uploadRetries: Int,
        uploadRetryDelay: TimeInterval
    ) throws
}

public enum FirebaseDistributionIPAUploadError: Error {
    case uploadStatusIsNotDone(status: FirebaseDistributionDTOs.UploadReleaseStatus)
    case uploadStatusIsMissingReleaseInfo(status: FirebaseDistributionDTOs.UploadReleaseStatus)
    case uploadStatusIsMissingUploadResult(status: FirebaseDistributionDTOs.UploadReleaseStatus)

    var status: FirebaseDistributionDTOs.UploadReleaseStatus {
        switch self {
        case let .uploadStatusIsNotDone(status),
             let .uploadStatusIsMissingReleaseInfo(status),
             let .uploadStatusIsMissingUploadResult(status):
            return status
        }
    }
}

public final class FirebaseDistributionIPAUploader {
    private let logger: Logging
    private let timeMeasurer: TimeMeasuring
    private let googleAuthClient: GoogleAuthAPIClientProtocol
    private let appDistributionClient: FirebaseDistributionAPIClientProtocol

    public init(
        logger: Logging,
        timeMeasurer: TimeMeasuring,
        googleAuthClient: GoogleAuthAPIClientProtocol,
        appDistributionClient: FirebaseDistributionAPIClientProtocol
    ) {
        self.logger = logger
        self.timeMeasurer = timeMeasurer
        self.googleAuthClient = googleAuthClient
        self.appDistributionClient = appDistributionClient
    }

    private func pollUploadedRelease(
        accessToken: FirebaseDistributionDTOs.AccessToken,
        uploadOperation: FirebaseDistributionDTOs.UploadReleaseOperation,
        retries: Int,
        retryDelay: TimeInterval
    ) -> AnyPublisher<FirebaseDistributionDTOs.Release, Error> {
        var retryNumber = 0

        let logError = { [logger] (errorDescription: String, status: FirebaseDistributionDTOs.UploadReleaseStatus?) in
            logger.error(errorDescription)
            if let parsedMessage = status?.error?.message {
                logger.error("Response error: " + parsedMessage.quoted)
            }
            if let status = status {
                logger.warn("Upload status: \(status.asPrettyJSON())")
            }
        }

        return appDistributionClient
            .getUploadStatus(
                accessToken: accessToken,
                operation: uploadOperation
            )
            .tryMap { [logger] uploadStatus -> FirebaseDistributionDTOs.UploadReleaseStatus in
                retryNumber += 1

                guard uploadStatus.done == true else {
                    logger
                        .warn(
                            "Waiting \(Int(retryDelay)) seconds until next upload status polling retry (\(retryNumber)/\(retries))..."
                        )
                    throw FirebaseDistributionIPAUploadError.uploadStatusIsNotDone(status: uploadStatus)
                }

                return uploadStatus
            }
            .retry(retries, delay: .seconds(retryDelay))
            .mapError { error -> Error in
                let uploadStatus = (error as? FirebaseDistributionIPAUploadError)?.status
                logError("Upload status polling has reached its retries limit.", uploadStatus)
                return error
            }
            .tryMap { [logger] uploadStatus -> FirebaseDistributionDTOs.Release in
                /// Here `uploadStatus.done` is true.

                guard let result = uploadStatus.response?.result else {
                    logError("Uploaded release status flagged as done but it doesn't have \"result\" info.", uploadStatus)
                    throw FirebaseDistributionIPAUploadError.uploadStatusIsMissingUploadResult(status: uploadStatus)
                }

                guard let release = uploadStatus.response?.release else {
                    logError("Uploaded release status flagged as done but it doesn't have \"release\" info.", uploadStatus)
                    throw FirebaseDistributionIPAUploadError.uploadStatusIsMissingReleaseInfo(status: uploadStatus)
                }

                switch result {
                case .releaseUpdated:
                    logger.success("Uploaded successfully; updated provisioning profile of existing release \(release).")
                case .releaseUnmodified:
                    logger.warn("The same binary was found in release \(release) with no changes.")
                case .releaseCreated, .unspecified:
                    logger.success("Uploaded binary successfully and created release \(release).")
                }

                return release
            }
            .eraseToAnyPublisher()
    }
}

// swiftformat:disable indent
extension FirebaseDistributionIPAUploader: FirebaseDistributionIPAUploading {
	public func uploadRelease(
	    fileName: String,
	    ipaData: Data,
	    releaseNotes: String,
	    testersEmails: [String],
	    testersGroupsAliases: [String],
	    uploadStatusPollingRetries: UInt = 60,
	    uploadStatusPollingRetryDelay: TimeInterval = 5,
	    uploadTimeout: TimeInterval = 600,
	    uploadRetries: Int = 1,
	    uploadRetryDelay: TimeInterval = 10
	) throws {
		logger.important("Uploading binary \(fileName.quoted) (size: \(ipaData.humanSize()))")
		logger.important("Release notes: \(releaseNotes.green.quoted)")

		let noTestersSpecified = testersEmails.isEmpty && testersGroupsAliases.isEmpty
		let testersLogMessage = noTestersSpecified
			? "No testers passed in."
			: "Testers emails: \(testersEmails), groups: \(testersGroupsAliases)."
		logger.important(testersLogMessage)

		let accessToken = try googleAuthClient.getAccessToken().await()

		let uploadOperation = try timeMeasurer.measure(description: "Uploading binary") {
			try appDistributionClient.uploadIPA(
			    accessToken: accessToken,
			    fileName: fileName,
			    data: ipaData,
			    timeout: uploadTimeout
			).retry(
			    uploadRetries,
			    delay: .seconds(uploadRetryDelay)
			).tryCatch { [logger] error -> AnyPublisher<FirebaseDistributionDTOs.UploadReleaseOperation, Error> in
				if case let NetworkingError.badStatusCode(response) = error,
				   response.status == .notFound
				{
					logger.error(
						"App Distribution could not find your app. " +
						"Make sure to onboard your app by pressing the \"Get started\" button " +
						"on the App Distribution page in the Firebase console: " +
						"https://console.firebase.google.com/project/_/appdistribution"
					)
				}

				throw error
			}.await(timeout: uploadTimeout)
		}

		let release = try timeMeasurer.measure(description: "Polling upload status") { [self] in
			try pollUploadedRelease(
			    accessToken: accessToken,
			    uploadOperation: uploadOperation,
			    retries: Int(uploadStatusPollingRetries),
			    retryDelay: uploadStatusPollingRetryDelay
			).await(timeout: uploadTimeout)
		}

		logger.important("Release notes: \(releaseNotes.green.quoted)")
		let releaseWithUpdatedNotes = try timeMeasurer.measure(description: "Updating release notes") {
			try appDistributionClient.updateReleaseNotes(
			    accessToken: accessToken,
			    release: release,
			    releaseNotes: releaseNotes
			).await()
		}

		guard !noTestersSpecified else {
			logger.warn(testersLogMessage)
			return
		}

		logger.important(testersLogMessage)
		try timeMeasurer.measure(description: "Distributing to testers") {
			try appDistributionClient.distribute(
			    accessToken: accessToken,
			    release: releaseWithUpdatedNotes,
			    emails: testersEmails,
			    groupsAliases: testersGroupsAliases
			).await()
		}
	}
}

// swiftformat:enable indent
