//

import Foundation
import SwiftlaneCore

public class NetworkingBasicAuthHeaderFactory: Encodable {
    public init() {}

    /// Encode `username` and `password` as Basic auth header.
    ///
    /// - Returns: `key` and `value` of auth header.
    ///
    /// `key` is always `"Authorization"`.
    ///
    /// `value` is `"Basic <auth data>"` where `<auth data>` is Base64 encoded `"username:password"` string.
    public func makeAuthHeader(
        username: String,
        password: String
    ) throws -> (key: String, value: String) {
        let base64CredentialsString = try [username, password].joined(separator: ":")
            .data(using: .utf8)
            .unwrap()
            .base64EncodedString()

        return ("Authorization", "Basic \(base64CredentialsString)")
    }
}
