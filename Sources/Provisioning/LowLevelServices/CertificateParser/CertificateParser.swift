//

import Foundation
import Security
import SwiftlaneCore

public struct Certificate {
    public let certificate: SecCertificate
    public let name: String?
    public let notValidBefore: Date?
    public let notValidAfter: Date?
}

public final class CertificateParser {
    private let filesManager: FSManaging

    public init(
        filesManager: FSManaging
    ) {
        self.filesManager = filesManager
    }

    public func parse(path _: AbsolutePath) throws -> Certificate {
        //		let data = try filesManager.readData(path, log: true)
//
        //		let certificate = try SecCertificateCreateWithData(nil, data as NSData).unwrap(
        //			errorDescription: "SecCertificateCreateWithData returned nil."
        //		)
//
        //		let values = SecCertificateCopyValues(certificate, nil, nil) as? [String: Any]
//
        //		let fingerprintsArrayContainer = values?["Fingerprints"] as? [String: Any]
        //		let fingerprintsArray = try (fingerprintsArrayContainer?["value"] as? [[String: Any]]).unwrap()
//
        //		let _prints = Dictionary<String, Data>(uniqueKeysWithValues: fingerprintsArray.compactMap {
        //			($0["label"] as! String, $0["value"] as! Data)
        //		})
//
        fatalError("Not implemented")
    }
}
