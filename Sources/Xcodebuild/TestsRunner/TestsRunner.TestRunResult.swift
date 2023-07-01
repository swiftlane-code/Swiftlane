//

import Foundation

import Simulator
import SwiftlaneCore

public extension TestsRunner {
    struct TestRunResult {
        public let simulator: Simulator
        public let tests: [XCTestFunction]
        public let xcresultPath: AbsolutePath?
        public let runLogsPaths: LogsPathPair
        public let junitPath: AbsolutePath?
        public let result: Result<Void, XcodebuildError>
    }
}
