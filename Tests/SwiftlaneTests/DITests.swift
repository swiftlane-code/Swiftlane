//

import SwiftlaneCore
import XCTest

@testable import Swiftlane

final class DITests: XCTestCase {
    func testAllDIObjects() {
        DependencyResolver.shared.register(Logging.self) {
            DetailedLogger(logLevel: .verbose)
        }
        DependenciesFactory.registerProducers()
        DependencyResolver.shared.register(EnvironmentValueReading.self) {
            struct Fake: ProcessInfoProtocol {
                var environment: [String: String] = [
                    "GITLAB_API_ENDPOINT": "https://127.0.0.1",
                    "PROJECT_ACCESS_TOKEN": "PROJECT_ACCESS_TOKEN",
                    "JIRA_API_TOKEN": "JIRA_API_TOKEN",
                    "JIRA_API_ENDPOINT": "https://127.0.0.1",
                    "GIT_AUTHOR_EMAIL": "GIT_AUTHOR_EMAIL",
                    "GITLAB_GROUP_DEV_TEAM_ID_TO_FETCH_MEMBERS": "123123",
                    "ADP_ARTIFACTS_REPO": "https://127.0.0.1",
                ]
                var arguments: [String] = []
                var hostName: String = "host"
                var processName: String = "processName"
                var processIdentifier: Int32 = 123
                var globallyUniqueString: String = "globallyUniqueString"
            }
            return EnvironmentValueReader(processInfo: Fake())
        }
        
        for key in DependencyResolver.shared.allRegisteredTypes() {
            print(key)
            let _: Any = DependencyResolver.shared.resolve(key, .shared)
        }
    }
}
