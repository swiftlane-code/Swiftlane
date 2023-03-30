//

import Foundation
import SwiftlaneCore

public protocol XcodebuildErrorParsing {
    func transformError(_ error: Error) -> XcodebuildError
}

// swiftformat:disable indent
public struct XcodebuildError: Error, CustomStringConvertible {
	public let reason: Reason
	public let underlyingError: Error

	public var description: String {
		"XcodebuildError: \n" +
		"\treason: \(reason)\n" +
		"\tunderlyingError: \(underlyingError)"
	}

	/// The higher the value - the later failed stage was.
	public enum Reason: Int, Equatable, CustomStringConvertible {
		case buildingFailed = 5
		case failedToInstallOrLaunchTestRunner = 6
		case testingFailed = 7
		case unknown = 8
		case timedOut = 9

		public var description: String {
			switch self {
			case .buildingFailed:
				return "BUILD stage failed (not TEST stage)."
			case .testingFailed:
				return "BUILD stage succeeded but TEST stage FAILED."
			case .failedToInstallOrLaunchTestRunner:
				return "Failed to install or launch the test runner. " +
				"Are you running `xcodebuild test-without-building` without prior " +
				"running `xcodebuild build`?"
			case .unknown:
				return "Unable to detect failure reason."
			case .timedOut:
				return "Timed out."
			}
		}
	}
}

// swiftformat:enable indent

public class XcodebuildErrorParser {
    public init() {}

    private func extractReason(from error: ShError) -> XcodebuildError.Reason {
        let buildingFailedHints: [StringMatcher] = [
            .contains("Testing cancelled because the build failed."),
            .contains("The following build commands failed:"),
            .contains("** BUILD FAILED **"),
        ]

        let testingFailedHints: [StringMatcher] = [
            .contains("Testing failed:"),
            .contains("Failing tests:"),
            .contains("** TEST FAILED **"),
            .contains("** TEST EXECUTE FAILED **"),
        ]

        let runnerNotFoundHints: [StringMatcher] = [
            .contains("Failed to install or launch the test runner"),
        ]

        switch error {
        case let .nonZeroExitCode(_, output, _):
            guard let stderr = output.stderrText else {
                return .unknown
            }

            ///
            /// When running `$ xcodebuild test` and BUILDING fails:
            ///		`"** BUILD FAILED **"` 	**WILL NOT BE** in stderr;
            ///		`"** TEST FAILED **"` 	**WILL BE** in stderr.
            ///
            ///	That's why we firstly check for ``buildingFailedHints`` and then for ``testingFailedHints``.
            ///

            if buildingFailedHints.isMatching(string: stderr) {
                return .buildingFailed
            }
            if runnerNotFoundHints.isMatching(string: stderr) {
                return .failedToInstallOrLaunchTestRunner
            }
            if testingFailedHints.isMatching(string: stderr) {
                return .testingFailed
            }

        case .executionTimedOut, .closingPipesTimedOut:
            return .timedOut
        }

        return .unknown
    }
}

extension XcodebuildErrorParser: XcodebuildErrorParsing {
    public func transformError(_ error: Error) -> XcodebuildError {
        let reason = (error as? ShError).map(extractReason(from:))
        return XcodebuildError(
            reason: reason ?? .unknown,
            underlyingError: error
        )
    }
}
