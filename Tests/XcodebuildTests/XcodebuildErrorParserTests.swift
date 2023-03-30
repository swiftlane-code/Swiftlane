//

import Foundation
import SwiftlaneCore
import SwiftlaneUnitTestTools
import XCTest

@testable import Xcodebuild

// swiftformat:disable indent
class XcodebuildErrorParserTests: XCTestCase {
	var parser: XcodebuildErrorParser!

	override func setUp() {
		super.setUp()

		parser = XcodebuildErrorParser()
	}

	func test_buildCommand_buildFailed() throws {
		// $ xcodebuild build
		let error = makeError(
			stderr: #"""
				** BUILD FAILED **


				The following build commands failed:
					CompileSwift normal arm64 (in target 'FirebaseIPATest' from project 'FirebaseIPATest')
					SwiftCompile normal arm64 Compiling\ ContentView.swift,\ FirebaseIPATestApp.swift /Users/user/git/FirebaseIPATest/FirebaseIPATest/ContentView.swift /Users/user/git/FirebaseIPATest/FirebaseIPATest/FirebaseIPATestApp.swift (in target 'FirebaseIPATest' from project 'FirebaseIPATest')
				(2 failures)
				"""#
		)
		XCTAssertEqual(parser.transformError(error).reason, .buildingFailed)
	}

	func test_testCommand_buildFailed_1() throws {
		// $ xcodebuild test
		let error = makeError(
			stderr: #"""
				Testing failed:
					No such module 'BULLSHIT'
					Testing cancelled because the build failed.

				** TEST FAILED **


				The following build commands failed:
					CompileSwift normal arm64 /Users/user/git/FirebaseIPATest/FirebaseIPATest/ContentView.swift (in target 'FirebaseIPATest' from project 'FirebaseIPATest')
					SwiftCompile normal arm64 Compiling\ ContentView.swift /Users/user/git/FirebaseIPATest/FirebaseIPATest/ContentView.swift (in target 'FirebaseIPATest' from project 'FirebaseIPATest')
					SwiftCompile normal arm64 Compiling\ FirebaseIPATestApp.swift /Users/user/git/FirebaseIPATest/FirebaseIPATest/FirebaseIPATestApp.swift (in target 'FirebaseIPATest' from project 'FirebaseIPATest')
					CompileSwift normal arm64 /Users/user/git/FirebaseIPATest/FirebaseIPATest/FirebaseIPATestApp.swift (in target 'FirebaseIPATest' from project 'FirebaseIPATest')
				(4 failures)
				"""#
		)
		XCTAssertEqual(parser.transformError(error).reason, .buildingFailed)
	}

	func test_testCommand_buildFailed_2() throws {
		// $ xcodebuild test
		let error = makeError(
			stderr: #"""
				Testing failed:
					Command CompileSwift failed with a nonzero exit code
					Expected 'func' keyword in instance method declaration
					Found an unexpected second identifier in function declaration; is there an accidental break?
					Expected '(' in argument list of function declaration
					Expected '{' in body of function declaration
					Testing cancelled because the build failed.

				** TEST FAILED **


				The following build commands failed:
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/AppVersionProvider/AppVersionProviding.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/Extensions/Array+.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/Validation/Validators/B2B/BIKValidator.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/Operations/BaseOperation.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/Extensions/Bool+.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/Types/BoundingBox.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/Protocols/BuildInfoReading.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/Extensions/Bundle+.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/Types/BusinessLogic/BusinessDocumentTypes.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/Validation/Validators/CardExpirationValidator.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/Validation/Validators/CardNumberValidator.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/CodeCoverageFiller.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/Extensions/Collection+.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/Types/CollectionChanges.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/Extensions/Color+.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/Constants.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/Extensions/Date+.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/DebouncedValueProvider/DebouncedValue.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/Extensions/Decimal+.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/Formatters/Decimal/DecimalFormatterProtocol.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/Extensions/Decodable+.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwift normal x86_64 /Users/user/builds/adadad/0/gitlab.user/ios-app-test-pipelines/OurFoundation/Main/Extensions/Codable/DecodingContainer+.swift (in target 'OurFoundation' from project 'SuperApp')
					CompileSwiftSources normal x86_64 com.apple.xcode.tools.swift.compiler (in target 'OurFoundation' from project 'SuperApp')
				(23 failures)
				"""#
		)
		XCTAssertEqual(parser.transformError(error).reason, .buildingFailed)
	}

	func test_testCommand_testsFailed_1() throws {
		// $ xcodebuild test
		let error = makeError(
			stderr: #"""
				2022-10-27 17:48:53.245 xcodebuild[95888:16387114] Requested but did not find extension point with identifier Xcode.IDEKit.ExtensionSentinelHostApplications for extension Xcode.DebuggerFoundation.AppExtensionHosts.watchOS of plug-in com.apple.dt.IDEWatchSupportCore
				2022-10-27 17:48:53.245 xcodebuild[95888:16387114] Requested but did not find extension point with identifier Xcode.IDEKit.ExtensionPointIdentifierToBundleIdentifier for extension Xcode.DebuggerFoundation.AppExtensionToBundleIdentifierMap.watchOS of plug-in com.apple.dt.IDEWatchSupportCore
				2022-10-27 17:56:02.481 xcodebuild[95888:16387114] [MT] IDETestOperationsObserverDebug: 154.883 elapsed -- Testing started completed.
				2022-10-27 17:56:02.481 xcodebuild[95888:16387114] [MT] IDETestOperationsObserverDebug: 0.000 sec, +0.000 sec -- start
				2022-10-27 17:56:02.481 xcodebuild[95888:16387114] [MT] IDETestOperationsObserverDebug: 154.883 sec, +154.883 sec -- end
				Failing tests:
					ScenesTests:
						SelectionPresenterTests.test_openScreen_thenSelectFilter()

				** TEST FAILED **
				"""#
		)
		XCTAssertEqual(parser.transformError(error).reason, .testingFailed)
	}

	func test_testWithoutBuildingCommand_testsFailed_1() throws {
		// $ xcodebuild clean test-without-building
		let error = makeError(
			stderr: #"""
				2022-11-02 20:44:21.625 xcodebuild[83206:45067359] [MT] IDETestOperationsObserverDebug: 40.365 elapsed -- Testing started completed.
				2022-11-02 20:44:21.625 xcodebuild[83206:45067359] [MT] IDETestOperationsObserverDebug: 0.000 sec, +0.000 sec -- start
				2022-11-02 20:44:21.625 xcodebuild[83206:45067359] [MT] IDETestOperationsObserverDebug: 40.365 sec, +40.365 sec -- end
				Testing failed:
					Не удается установить «FirebaseIPATest»
					FirebaseIPATest encountered an error (Failed to install or launch the test runner. If you believe this error represents a bug, please attach the result bundle at /Users/user/Library/Developer/Xcode/DerivedData/FirebaseIPATest-fnxcuevgaboctzfnydflrifymiio/Logs/Test/Test-FirebaseIPATest-2022.11.02_20-43-41-+0600.xcresult. (Underlying Error: Не удается установить «FirebaseIPATest». Повторите попытку позже. Failed to get FD to bundle executable at /Users/user/Library/Developer/XCTestDevices/CB4162C6-0B92-4831-80A6-96D0F9721495/data/Library/Caches/com.apple.mobile.installd.staging/temp.v7KilF/extracted/FirebaseIPATest.app/FirebaseIPATest. (Underlying Error: Failed to get FD to bundle executable at /Users/user/Library/Developer/XCTestDevices/CB4162C6-0B92-4831-80A6-96D0F9721495/data/Library/Caches/com.apple.mobile.installd.staging/temp.v7KilF/extracted/FirebaseIPATest.app/FirebaseIPATest. (Underlying Error: Failed to open /Users/user/Library/Developer/XCTestDevices/CB4162C6-0B92-4831-80A6-96D0F9721495/data/Library/Caches/com.apple.mobile.installd.staging/temp.v7KilF/extracted/FirebaseIPATest.app/FirebaseIPATest. No such file or directory))))

				** TEST EXECUTE FAILED **
				"""#
		)
		XCTAssertEqual(parser.transformError(error).reason, .failedToInstallOrLaunchTestRunner)
	}

	private func makeError(stderr: String?) -> ShError {
		ShError.nonZeroExitCode(
		    command: .random(),
		    output: ShellOutput(stdoutText: nil, stderrText: stderr),
		    exitCode: 65
		)
	}
}
