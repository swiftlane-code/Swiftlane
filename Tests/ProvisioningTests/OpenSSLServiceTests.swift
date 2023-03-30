//

import Foundation
import SwiftlaneCore
import SwiftlaneCoreMocks
import SwiftlaneUnitTestTools
import XCTest

@testable import Provisioning

class OpenSSLServiceTests: XCTestCase {
    var openssl: OpenSSLService!

    override func setUp() {
        super.setUp()

        let logger = DetailedLogger(logLevel: .verbose)

        let sigIntHandler = SigIntHandler(logger: logger)
        let xcodeChecker = XcodeChecker()

        let shell = ShellExecutor(
            sigIntHandler: sigIntHandler,
            logger: logger,
            xcodeChecker: xcodeChecker,
            filesManager: FSManagingMock()
        )

        let filesManager = FSManager(
            logger: logger,
            fileManager: FileManager.default
        )

        openssl = OpenSSLService(
            shell: shell,
            filesManager: filesManager
        )
    }

    func test_certificateFingerprint() throws {
        // given
        let certPath = try Bundle.module.getStubURL(path: "self-signed-ssl.cer").path

        // when
        let fingerprint_sha1 = try openssl.x509Fingerprint(inFile: AbsolutePath(certPath), format: .der, msgDigest: .sha1)
        let fingerprint_md5 = try openssl.x509Fingerprint(inFile: AbsolutePath(certPath), format: .der, msgDigest: .md5)

        // then
        XCTAssertEqual(fingerprint_sha1, "A2:4C:95:25:30:EC:CF:00:30:B0:C4:C8:1E:B4:7F:19:A7:EF:1D:8B")
        XCTAssertEqual(fingerprint_md5, "06:5B:D4:FF:41:A2:24:E8:EA:DF:8E:8C:A9:FE:A1:7F")
    }

    func test_createCSR() throws {
        // given
        let privateKey = try Bundle.module.readStubText(path: "rsa_key")
        let expectedCSR = try Bundle.module.readStubText(path: "rsa_key_csr")

        // when
        let csr = try openssl.createCSR(
            commonName: "Swiftlane CSR test",
            privateKey: privateKey,
            digest: .sha256
        )

        // then
        XCTAssertEqual(csr, expectedCSR)
    }
}
