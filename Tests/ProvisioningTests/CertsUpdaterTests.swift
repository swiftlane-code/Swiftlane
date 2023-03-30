//

import Foundation
import SwiftlaneCore
import SwiftlaneCoreMocks
import SwiftlaneUnitTestTools
import XCTest

@testable import AppStoreConnectAPI
@testable import Provisioning

class CertsUpdaterTests: XCTestCase {
    var updater: CertsUpdater!

    var logger: LoggingMock!
    var repo: CertsRepositoryProtocolMock!
    var generator: CertsGeneratingMock!
    var filesManager: FSManagingMock!

    override func setUp() {
        super.setUp()

        logger = LoggingMock()
        repo = CertsRepositoryProtocolMock()
        generator = CertsGeneratingMock()
        filesManager = FSManagingMock()

        updater = CertsUpdater(
            logger: logger,
            repo: repo,
            generator: generator,
            filesManager: filesManager
        )

        logger.given(.logLevel(getter: .verbose))
    }

    override func tearDown() {
        super.tearDown()

        updater = nil

        logger = nil
        repo = nil
        generator = nil
        filesManager = nil
    }

    func test_nothingToUpdate() throws {
        // given
        let clonedRepoPath = AbsolutePath.random(lastComponent: "clonedRepoPath")
        let bundleID = "com.some.app"
        let provision = MobileProvision(
            AppIDName: "some app id",
            ApplicationIdentifierPrefix: [],
            CreationDate: Date(),
            Platform: [],
            IsXcodeManaged: false,
            ExpirationDate: Date(),
            Name: "Some App",
            TeamIdentifier: [],
            Entitlements: MobileProvision.MobileProvisionEntitlements(applicationIdentifier: bundleID),
            TeamName: "",
            TimeToLive: 0,
            UUID: "",
            Version: 0,
            DeveloperCertificates: []
        )

        generator.given(
            .verifyBundleIDsExistInAppStoreConnect(
                bundleIDs: .value([bundleID]),
                willReturn: [
                    AppStoreConnectAPIDTOs.BundleID(
                        name: "Some app",
                        identifier: bundleID,
                        appStoreConnectID: "ABCDEF"
                    ),
                ]
            )
        )

        repo.given(
            .getCertificateID(
                certificateType: .value(.distribution),
                clonedRepoPath: .any,
                willReturn: ["DISTRIBUTION_CERTID"]
            )
        )

        repo.given(
            .getProvisioningProfile(
                clonedRepoPath: .any,
                profileType: .value(.adhoc),
                bundleID: .value(bundleID),
                willReturn: provision
            )
        )

        generator.given(
            .verifyCertificate(
                id: .value("DISTRIBUTION_CERTID"),
                willReturn: true
            )
        )

        generator.given(
            .verifyProfile(
                profile: .value(provision),
                willReturn: true
            )
        )

        // when
        try updater.updateCertificatesAndProfiles(
            updateConfig: CertsUpdateConfig(
                common: CertsCommonConfig(
                    repoURL: .random(),
                    clonedRepoDir: clonedRepoPath,
                    repoBranch: "branch",
                    encryptionPassword: "pass"
                ),
                bundleIDs: ["com.some.app"],
                profileTypes: [.adhoc]
            )
        )

        // then
        filesManager.verify(.delete(.any), count: .once)

        generator.verify(.createCertificate(certificateType: .any), count: .never)
        generator.verify(
            .createProvisioningProfile(profileName: .any, for: .any, profileType: .any, certificateID: .any),
            count: .never
        )
    }

    func test_updateProfile() throws {
        // given
        let clonedRepoPath = AbsolutePath.random(lastComponent: "clonedRepoPath")
        let bundleID = "com.some.app"
        let bundleIDData = AppStoreConnectAPIDTOs.BundleID(
            name: "Some app",
            identifier: bundleID,
            appStoreConnectID: "ABCDEF"
        )
        let provision = MobileProvision(
            AppIDName: "some app id",
            ApplicationIdentifierPrefix: [],
            CreationDate: Date(),
            Platform: [],
            IsXcodeManaged: false,
            ExpirationDate: Date(),
            Name: "Some App",
            TeamIdentifier: [],
            Entitlements: MobileProvision.MobileProvisionEntitlements(applicationIdentifier: bundleID),
            TeamName: "",
            TimeToLive: 0,
            UUID: "",
            Version: 0,
            DeveloperCertificates: []
        )

        generator.given(
            .verifyBundleIDsExistInAppStoreConnect(
                bundleIDs: .value([bundleID]),
                willReturn: [
                    bundleIDData,
                ]
            )
        )

        repo.given(
            .getCertificateID(
                certificateType: .value(.distribution),
                clonedRepoPath: .any,
                willReturn: ["DISTRIBUTION_CERTID"]
            )
        )

        repo.given(
            .getProvisioningProfile(
                clonedRepoPath: .any,
                profileType: .value(.adhoc),
                bundleID: .value(bundleID),
                willReturn: provision
            )
        )

        generator.given(
            .verifyCertificate(
                id: .value("DISTRIBUTION_CERTID"),
                willReturn: true
            )
        )

        generator.given(
            .verifyProfile(
                profile: .value(provision),
                willReturn: false
            )
        )

        generator.given(
            .createProvisioningProfile(
                profileName: .any,
                for: .value(bundleIDData),
                profileType: .value(.adhoc),
                certificateID: .value("DISTRIBUTION_CERTID"),
                willReturn: Data(count: 123)
            )
        )

        // when
        try updater.updateCertificatesAndProfiles(
            updateConfig: CertsUpdateConfig(
                common: CertsCommonConfig(
                    repoURL: .random(),
                    clonedRepoDir: clonedRepoPath,
                    repoBranch: "branch",
                    encryptionPassword: "pass"
                ),
                bundleIDs: ["com.some.app"],
                profileTypes: [.adhoc]
            )
        )

        // then
        filesManager.verify(.delete(.any), count: .once)

        generator.verify(.createCertificate(certificateType: .any), count: .never)
        generator.verify(
            .createProvisioningProfile(
                profileName: .any,
                for: .any,
                profileType: .any,
                certificateID: .any
            ),
            count: .once
        )

        repo.verify(
            .saveProfile(
                profileData: .value(Data(count: 123)),
                clonedRepoPath: .any,
                profileType: .value(.adhoc),
                bundleID: .value(bundleID)
            )
        )
    }

    func test_updateCertificateAndProfile() throws {
        // given
        let clonedRepoPath = AbsolutePath.random(lastComponent: "clonedRepoPath")
        let bundleID = "com.some.app"
        let bundleIDData = AppStoreConnectAPIDTOs.BundleID(
            name: "Some app",
            identifier: bundleID,
            appStoreConnectID: "ABCDEF"
        )
        let provision = MobileProvision(
            AppIDName: "some app id",
            ApplicationIdentifierPrefix: [],
            CreationDate: Date(),
            Platform: [],
            IsXcodeManaged: false,
            ExpirationDate: Date(),
            Name: "Some App",
            TeamIdentifier: [],
            Entitlements: MobileProvision.MobileProvisionEntitlements(applicationIdentifier: bundleID),
            TeamName: "",
            TimeToLive: 0,
            UUID: "",
            Version: 0,
            DeveloperCertificates: []
        )

        generator.given(
            .verifyBundleIDsExistInAppStoreConnect(
                bundleIDs: .value([bundleID]),
                willReturn: [
                    bundleIDData,
                ]
            )
        )

        repo.given(
            .getCertificateID(
                certificateType: .value(.distribution),
                clonedRepoPath: .any,
                willReturn: ["DISTRIBUTION_CERTID"]
            )
        )

        repo.given(
            .getProvisioningProfile(
                clonedRepoPath: .any,
                profileType: .value(.adhoc),
                bundleID: .value(bundleID),
                willReturn: provision
            )
        )

        generator.given(
            .verifyCertificate(
                id: .value("DISTRIBUTION_CERTID"),
                willReturn: false
            )
        )

        generator.given(
            .verifyProfile(
                profile: .value(provision),
                willReturn: false
            )
        )

        class FakeSecKey {}

        let key = unsafeBitCast(FakeSecKey(), to: SecKey.self)

        generator.given(
            .createCertificate(
                certificateType: .value(.distribution),
                willReturn: (cert: Data(count: 33), certID: "NEW_CERT_ID", privateKey: key)
            )
        )

        generator.given(
            .createProvisioningProfile(
                profileName: .any,
                for: .value(bundleIDData),
                profileType: .value(.adhoc),
                certificateID: .value("NEW_CERT_ID"),
                willReturn: Data(count: 123)
            )
        )

        // when
        try updater.updateCertificatesAndProfiles(
            updateConfig: CertsUpdateConfig(
                common: CertsCommonConfig(
                    repoURL: .random(),
                    clonedRepoDir: clonedRepoPath,
                    repoBranch: "branch",
                    encryptionPassword: "pass"
                ),
                bundleIDs: ["com.some.app"],
                profileTypes: [.adhoc]
            )
        )

        // then
        filesManager.verify(.delete(.any), count: .once)

        generator.verify(
            .createProvisioningProfile(
                profileName: .any,
                for: .any,
                profileType: .any,
                certificateID: .any
            ),
            count: .once
        )

        repo.verify(
            .saveProfile(
                profileData: .value(Data(count: 123)),
                clonedRepoPath: .any,
                profileType: .value(.adhoc),
                bundleID: .value(bundleID)
            )
        )

        repo.verify(
            .saveCertificate(
                clonedRepoPath: .any,
                certificateType: .value(.distribution),
                cert: .value(Data(count: 33)),
                certID: .value("NEW_CERT_ID"),
                privateKey: .value(key)
            )
        )
    }
}
