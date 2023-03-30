//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol XCTestRunFinding {
    func findXCTestRunFile(derivedDataPath: AbsolutePath) throws -> AbsolutePath
}

public class XCTestRunFinder {
    public enum Errors: Error {
        case xcTestRunFileNotFound(inDerivedDataPath: String)
    }

    let filesManager: FSManaging

    public init(
        filesManager: FSManaging
    ) {
        self.filesManager = filesManager
    }
}

extension XCTestRunFinder: XCTestRunFinding {
    // swiftformat:disable indent
	public func findXCTestRunFile(derivedDataPath: AbsolutePath) throws -> AbsolutePath {
		guard
			let path = try filesManager.find(derivedDataPath)
				.first(where: { $0.string.hasSuffix(".xctestrun") })
		else {
			throw Errors.xcTestRunFileNotFound(inDerivedDataPath: derivedDataPath.string)
		}
		return path
	}
	// swiftformat:enable indent
}
