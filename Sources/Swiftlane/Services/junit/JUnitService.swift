//

import Foundation
import SwiftlaneCore
import XMLCoder

// sourcery: AutoMockable
public protocol JUnitServicing {
    func parseJUnit(filePath: AbsolutePath) throws -> JUnitTestSuites
    func mergeJUnit(filesPaths: [AbsolutePath]) throws -> JUnitTestSuites
    func mergeJUnit(filesPaths: [AbsolutePath], into mergedJUnitPath: AbsolutePath) throws
}

public class JUnitService {
    private let filesManager: FSManaging

    public init(
        filesManager: FSManaging
    ) {
        self.filesManager = filesManager
    }

    private func merge(suites: [JUnitTestSuites]) -> JUnitTestSuites {
        var testsuite: [JUnitTestSuites.TestSuite] = []
        var name = ""
        var tests = 0
        var failures = 0
        suites.forEach {
            name = $0.name
            tests += $0.tests
            failures += $0.failures
            testsuite += $0.testsuite
        }
        return JUnitTestSuites(testsuite: testsuite, name: name, tests: tests, failures: failures)
    }
}

extension JUnitService: JUnitServicing {
    public func parseJUnit(filePath: AbsolutePath) throws -> JUnitTestSuites {
        let data = try filesManager.readData(filePath, log: true)

        return try XMLDecoder().decode(JUnitTestSuites.self, from: data)
    }

    public func mergeJUnit(filesPaths: [AbsolutePath]) throws -> JUnitTestSuites {
        let junitFiles = try filesPaths.map { try filesManager.readData($0, log: true) }

        let suites = try junitFiles.map { try XMLDecoder().decode(JUnitTestSuites.self, from: $0) }

        let result = merge(suites: suites)

        return result
    }

    public func mergeJUnit(filesPaths: [AbsolutePath], into mergedJUnitPath: AbsolutePath) throws {
        let mergedSuites = try mergeJUnit(filesPaths: filesPaths)

        let encoder = XMLEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.prettyPrintIndentation = .spaces(2)

        let data = try encoder.encode(
            mergedSuites,
            withRootKey: "testsuites",
            header: XMLHeader(version: 1.0, encoding: "UTF-8")
        )

        try filesManager.write(mergedJUnitPath, data: data)
    }
}
