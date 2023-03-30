//

import Foundation

public enum OpenSSLX509Options {
    /// print serial number value
    public static var serial: String { "-serial" }

    /// print subject hash value
    public static var subject_hash: String { "-subject_hash" }

    /// print old-style (MD5) subject hash value
    public static var subject_hash_old: String { "-subject_hash_old" }

    /// print issuer hash value
    public static var issuer_hash: String { "-issuer_hash" }

    /// print old-style (MD5) issuer hash value
    public static var issuer_hash_old: String { "-issuer_hash_old" }

    /// print subject DN
    public static var subject: String { "-subject" }

    /// print issuer DN
    public static var issuer: String { "-issuer" }

    /// print email address(es)
    public static var email: String { "-email" }

    /// notBefore field
    public static var startdate: String { "-startdate" }

    /// notAfter field
    public static var enddate: String { "-enddate" }

    /// print out certificate purposes
    public static var purpose: String { "-purpose" }

    /// both Before and After dates
    public static var dates: String { "-dates" }

    /// print the RSA key modulus
    public static var modulus: String { "-modulus" }

    /// output the public key
    public static var pubkey: String { "-pubkey" }

    /// print the certificate fingerprint
    public static var fingerprint: String { "-fingerprint" }

    /// output certificate alias
    public static var alias: String { "-alias" }

    /// print OCSP hash values for the subject name and public key
    public static var ocspid: String { "-ocspid" }

    /// print OCSP Responder URL(s)
    public static var ocsp_uri: String { "-ocsp_uri" }

    /// print the certificate in text form
    public static var text: String { "-text" }

    /// no certificate output
    public static var noout: String { "-noout" }
}
