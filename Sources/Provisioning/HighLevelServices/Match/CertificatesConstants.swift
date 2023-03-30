//

import Foundation

public enum CodeSigningCertificateType: String {
    case distribution
    case development
}

public enum ProvisionProfileType: String {
    case appstore
    case adhoc
    case development
}

internal enum CertificatesConstants {
    static let certificateFileExtension = ".cer"
    static let privateKeyExtension = ".p12"
}
