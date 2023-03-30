//

import Combine
import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol XCTestParsing {
    func parseCompiledTestFunctions(xctestPath: AbsolutePath) throws -> [String]
}

public class XCTestParser {
    public enum Errors: Error {
        case binaryDoesntExist(binaryPath: String)
    }

    let shell: ShellExecuting
    let filesManager: FSManaging
    let logger: Logging

    public init(
        shell: ShellExecuting,
        filesManager: FSManaging,
        logger: Logging
    ) {
        self.shell = shell
        self.filesManager = filesManager
        self.logger = logger
    }

    // swiftformat:disable indent
	private func dumpTestFunctions(binaryPath: AbsolutePath) throws -> [String] {
		guard filesManager.fileExists(binaryPath) else {
			throw Errors.binaryDoesntExist(binaryPath: binaryPath.string)
		}

		/// Extract all test functions from compiled binary inside `.xctest` bundle.
		/// This magic is taken from here:
		/// https://github.com/lyndsey-ferguson/xctest_list/blob/9a34c1c974902cf389eeb03192d7039460a71937/lib/xctest_list.rb#L57
		let stdoutText = try shell.run(
		    """
			nm -gU '\(binaryPath)' \
			| cut -d' ' -f3 \
			| xargs -s 131072 xcrun swift-demangle \
			| cut -d' ' -f3 \
			| grep -e '[\\.|_]'test
			""",
		    log: .silent
		).stdoutText.unwrap()

		let functions = stdoutText
			.split(separator: "\n")
			.map { funcSignature in
				funcSignature
					.replacingOccurrences(of: "()", with: "")
					.replacingOccurrences(of: ".", with: "/")
			}

		return functions
	}
	// swiftformat:enable indent
}

extension XCTestParser: XCTestParsing {
    public func parseCompiledTestFunctions(xctestPath: AbsolutePath) throws -> [String] {
        let binaryPath = xctestPath
            .appending(path: xctestPath.lastComponent.deletingExtension)

        let functions = try dumpTestFunctions(binaryPath: binaryPath)
        logger.info("Parsed \(functions.count) built tests in \(binaryPath)")
        return functions
    }
}
