//

import Combine
import Foundation
import SwiftlaneCore

/// Either `selectedTests` or `skippedTests` will not be empty.
public struct XCTestPlanInfo: Equatable {
    public let name: String
    public let selectedTests: [String]
    public let skippedTests: [String]
}

// sourcery: AutoMockable
public protocol XCTestPlanParsing {
    func parseTestPlan(path xctestplanPath: AbsolutePath) throws -> XCTestPlanInfo
}

public class XCTestPlanParser {
    public enum Errors: Error, Equatable {
        case notXCTestPlanFile(String)
    }

    private let filesManager: FSManaging

    public init(
        filesManager: FSManaging
    ) {
        self.filesManager = filesManager
    }

    private func parseRaw(xctestplanPath: AbsolutePath) throws -> (name: String, XCTestPlanDecodable) {
        guard xctestplanPath.string.hasSuffix(".xctestplan") else {
            throw Errors.notXCTestPlanFile(xctestplanPath.string)
        }

        let data = try filesManager.readData(xctestplanPath, log: true)
        // Why JSONDecoder is not injected? Because it's an implementation detail and should be black-box tested.
        let info = try JSONDecoder().decode(XCTestPlanDecodable.self, from: data)

        return (
            xctestplanPath.string.lastPathComponent.deletingPathExtension,
            info
        )
    }
}

extension XCTestPlanParser: XCTestPlanParsing {
    public func parseTestPlan(path xctestplanPath: AbsolutePath) throws -> XCTestPlanInfo {
        let (name, planData) = try parseRaw(xctestplanPath: xctestplanPath)

        func fullTestName(_ rawTestName: String, target: XCTestPlanDecodable.TestTarget) -> String {
            target.target.name.appendingPathComponent(rawTestName)
        }

        let selectedTests = planData.testTargets
            .flatMap { target -> [String] in
                target.selectedTests?.map {
                    fullTestName($0, target: target)
                } ?? []
            }

        let skippedTests = planData.testTargets
            .flatMap { target -> [String] in
                target.skippedTests?.map {
                    fullTestName($0, target: target)
                } ?? []
            }

        let info = XCTestPlanInfo(
            name: name,
            selectedTests: selectedTests,
            skippedTests: skippedTests
        )

        return info
    }
}

private struct XCTestPlanDecodable: Decodable {
    public let configurations: [Configuration]
    //		public let defaultOptions: [String: Any]
    public let testTargets: [TestTarget]
    public let version: Int

    public struct Configuration: Decodable {
        public let id: String
        public let name: String
        //			public let options: [String:Any]
    }

    public struct TestTarget: Decodable {
        public let selectedTests: [String]?
        public let skippedTests: [String]?
        public let target: TargetDetails

        public struct TargetDetails: Decodable {
            public let containerPath: String
            public let identifier: String
            public let name: String
        }
    }
}
