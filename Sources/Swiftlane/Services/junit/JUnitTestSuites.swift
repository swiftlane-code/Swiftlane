//

import Foundation

public struct JUnitTestSuites: Codable {
    public let testsuite: [TestSuite]
    public let name: String
    public let tests: Int
    public let failures: Int

    public struct TestSuite: Codable {
        public let name: String
        public let tests: Int
        public let failures: Int
        public let testcase: [TestCase]

        public struct TestCase: Codable {
            public let classname: String
            public let name: String
            public let time: Float?

            public let failure: [Failure]?

            public struct Failure: Codable, Equatable {
                public let message: String
                public let file: String

                public enum CodingKeys: String, CodingKey {
                    case message
                    case file = ""
                }
            }
        }
    }
}
