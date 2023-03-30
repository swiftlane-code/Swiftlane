//

import Foundation
import Networking
import SwiftlaneUnitTestTools
import XCTest

class Stubs {
    static let decoder = JSONDecoder()

    /// Read dumped request and response from `Tests/JiraAPITests/Stubs/<route>`.
    /// - Parameters:
    ///   - route: part of url respective to baseURL of a NetworkingClient.
    ///   - uuid: uuid of request.
    static func readDump(route: String, uuid: String) throws -> NetworkingDumper.DumpEntry {
        let data = try Bundle.module.readStubData(path: "\(route)/\(uuid).json")
        return try decoder.decode(NetworkingDumper.DumpEntry.self, from: data)
    }
}
