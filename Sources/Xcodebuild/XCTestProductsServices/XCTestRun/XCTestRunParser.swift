//

import Combine
import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol XCTestRunParsing {
    func parseXCTestPaths(xcTestRunPath: AbsolutePath) throws -> [AbsolutePath]
}

public class XCTestRunParser {
    public enum Errors: Error {
        case notXCTestRunFile(String)
        case unableToDecodeXCTestRunPlist(
            simplePlistError: Error,
            testPlansPlistError: Error
        )
        case noXCTestPathsFound
    }

    private let filesManager: FSManaging
    private let xcTestRunFinder: XCTestRunFinding

    public init(
        filesManager: FSManaging,
        xcTestRunFinder: XCTestRunFinding
    ) {
        self.filesManager = filesManager
        self.xcTestRunFinder = xcTestRunFinder
    }

    /// Decode .xctestrun file generated for TestPlan-enabled testing scheme.
    private func decodeTestPlansPlist(data: Data) throws -> TestPlansXCTestRunDecodable {
        // Do not inject PropertyListDecoder, it's an implementation detail.
        let decoder = PropertyListDecoder()
        return try decoder.decode(
            TestPlansXCTestRunDecodable.self,
            from: data
        )
    }

    /// Decode .xctestrun file generated for non-TestPlan-enabled testing scheme.
    private func decodeSimplePlist(data: Data) throws -> [TestPlansXCTestRunDecodable.TestConfiguration.TestTarget] {
        // Do not inject PropertyListDecoder, it's an implementation detail.
        let decoder = PropertyListDecoder()
        let targetsDictionary = try decoder.decode(
            [String: TestTargetDecodingWrapper].self,
            from: data
        )
        return targetsDictionary.values.compactMap(\.testTarget)
    }
}

extension XCTestRunParser: XCTestRunParsing {
    public func parseXCTestPaths(xcTestRunPath: AbsolutePath) throws -> [AbsolutePath] {
        guard xcTestRunPath.string.hasSuffix(".xctestrun") else {
            throw Errors.notXCTestRunFile(xcTestRunPath.string)
        }

        let data = try filesManager.readData(xcTestRunPath, log: true)

        var testTargets: [TestPlansXCTestRunDecodable.TestConfiguration.TestTarget] = []

        do {
            let plist = try decodeTestPlansPlist(data: data)
            testTargets = try plist.TestConfigurations.first.unwrap().TestTargets
        } catch let testPlansPlistError {
            do {
                let plist = try decodeSimplePlist(data: data)
                testTargets = plist
            } catch let simplePlistError {
                throw Errors.unableToDecodeXCTestRunPlist(
                    simplePlistError: simplePlistError,
                    testPlansPlistError: testPlansPlistError
                )
            }
        }

        let xctestPaths = testTargets.flatMap(\.DependentProductPaths)
            .filter { $0.hasSuffix(".xctest") }
            .map { $0.replacingOccurrences(of: "__TESTROOT__/", with: "") }
            .map { try! RelativePath($0) }

        let fullXCTestPaths = xctestPaths.map {
            xcTestRunPath.deletingLastComponent.appending(path: $0)
        }

        guard !fullXCTestPaths.isEmpty else {
            throw Errors.noXCTestPathsFound
        }

        return Set(fullXCTestPaths).asArray.sorted()
    }
}

/// Hack: Simple xctestrun contains dictionary with `targetName : targetModel` key-value pairs.
/// But it also contains one special key-value pair with key `__xctestrun_metadata__` and we have to ignore it.
private enum TestTargetDecodingWrapper: Decodable {
    case testTarget(TestPlansXCTestRunDecodable.TestConfiguration.TestTarget)
    case xctestrunMetadata

    var testTarget: TestPlansXCTestRunDecodable.TestConfiguration.TestTarget? {
        if case let .testTarget(testTarget) = self {
            return testTarget
        }
        return nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let codingPath = container.codingPath.map(\.stringValue)

        if codingPath == ["__xctestrun_metadata__"] {
            self = .xctestrunMetadata
            return
        }

        let target = try container.decode(TestPlansXCTestRunDecodable.TestConfiguration.TestTarget.self)
        self = .testTarget(target)
    }
}

/// Implemented for plist with `__xctestrun_metadata__.FormatVersion` == 2
private struct TestPlansXCTestRunDecodable: Decodable {
    let TestConfigurations: [TestConfiguration]
    let TestPlan: TestPlan?

    struct TestConfiguration: Decodable {
        let Name: String
        let TestTargets: [TestTarget]

        struct TestTarget: Decodable {
            let BlueprintName: String
            let DependentProductPaths: [String]
            let IsUITestBundle: Bool?
            let IsXCTRunnerHostedTestBundle: Bool?
            let OnlyTestIdentifiers: [String]?
            let SkipTestIndetifiers: [String]?
            let ProductModuleName: String
            let TestBundlePath: String
            let TestHostPath: String
            let TestTimeoutsEnabled: Bool
        }
    }

    struct TestPlan: Decodable {
        let IsDefault: Bool
        let Name: String
    }
}
