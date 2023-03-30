//

import Foundation
import SwiftlaneCore
import SwiftlaneCoreMocks
import SwiftlaneUnitTestTools
import XCTest

@testable import Provisioning

class MobileProvisionParserTests: XCTestCase {
    var parser: MobileProvisionParser!

    var logger: LoggingMock!
    var shell: ShellExecutor!

    override func setUp() {
        super.setUp()

        logger = .init()
        shell = ShellExecutor(
            sigIntHandler: SigIntHandler(logger: logger),
            logger: logger,
            xcodeChecker: XcodeChecker(),
            filesManager: FSManagingMock()
        )

        parser = MobileProvisionParser(logger: logger, shell: shell)
        logger.given(.logLevel(getter: .verbose))
    }

    override func tearDown() {
        parser = nil

        shell = nil
        logger = nil

        super.tearDown()
    }

    func test_mobileProvisionIsParsedCorrectly() throws {
        // given
        let url = try Bundle.module.getStubURL(path: "match_AppStore_com.fakecompany.app.mobileprovision")
        let provisionPath = try AbsolutePath(url.path)
        let expectedProfileData = try Bundle.module.readStubData(path: "match_AppStore_com.fakecompany.app.plist")
        let expectedCertData = try Bundle.module.readStubData(path: "self-signed-ssl.cer")
        let expectedProfile = try PropertyListDecoder().decode(MobileProvision.self, from: expectedProfileData)

        // when
        let parsedProfile = try parser.parse(provisionPath: provisionPath)

        // then
        XCTAssertEqual(parsedProfile.UUID, "c723fe24-67de-4e76-9f7c-c93bf6c32766")
        XCTAssertEqual(parsedProfile, expectedProfile)
        XCTAssertEqual(parsedProfile.applicationBundleID, "com.fakecompany.app")
        XCTAssertEqual(parsedProfile.DeveloperCertificates, [expectedCertData])
    }
}
