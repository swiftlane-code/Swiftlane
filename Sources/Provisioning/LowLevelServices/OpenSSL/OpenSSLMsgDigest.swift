//

import Foundation

/// The message digest to use.  Possible values include md5 and sha1.  This option also applies to CRLs.
public enum OpenSSLMsgDigest: String {
    case gost_mac = "gost-mac"
    case streebog512
    case streebog256
    case md_gost94
    case md4
    case md5
    case md5_sha1 = "md5-sha1"
    case ripemd160
    case sha1
    case sha224
    case sha256
    case sha384
    case sha512
    case whirlpool
    case pbkdf2

    /// Returns `"-" + rawValue`
    public var asCliOption: String {
        "-" + rawValue
    }
}
