//

import Combine
import Foundation
import SwiftlaneCore

public struct XCTestFunction {
    public let name: String
}

public protocol XCTestServicing {
    func parseTests(derivedDataPath: AbsolutePath) throws -> AnyPublisher<[XCTestFunction], Error>
}

public class XCTestService {
    let xctestParser: XCTestParsing
    let xcTestRunFinder: XCTestRunFinding
    let xcTestRunParser: XCTestRunParsing

    public init(
        xctestParser: XCTestParsing,
        xcTestRunFinder: XCTestRunFinding,
        xcTestRunParser: XCTestRunParsing
    ) {
        self.xctestParser = xctestParser
        self.xcTestRunFinder = xcTestRunFinder
        self.xcTestRunParser = xcTestRunParser
    }
}

extension XCTestService: XCTestServicing {
    public func parseTests(derivedDataPath: AbsolutePath) throws -> AnyPublisher<[XCTestFunction], Error> {
        let xcTestRunPath = try xcTestRunFinder.findXCTestRunFile(derivedDataPath: derivedDataPath)
        let xcTestPaths = try xcTestRunParser.parseXCTestPaths(xcTestRunPath: xcTestRunPath)

        let publishers = xcTestPaths.sorted().map { xctestPath in
            performAsync {
                try self.xctestParser.parseCompiledTestFunctions(xctestPath: xctestPath)
            }
        }

        return Publishers.MergeMany(publishers)
            .collect()
            .map { arrayOfArrays in
                arrayOfArrays
                    .flatMap { $0 }
                    .sorted()
                    .map { XCTestFunction(name: $0) }
            }
            .eraseToAnyPublisher()
    }
}
