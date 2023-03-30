//

import ArgumentParser
import Foundation
import PerfectRainbow
import SwiftlaneCore

public protocol LogOutputTypeSettable {
    static var outputTarget: OutputTarget { get set }
}

extension Rainbow: LogOutputTypeSettable {}

public class RootCommandRunner {
    public let logsOutputTypeSetter: LogOutputTypeSettable.Type
    public let bufferSetter: StdIOWrapping
    public let xcodeChecker: XcodeChecking

    public init(
        logsOutputTypeSetter: LogOutputTypeSettable.Type,
        bufferSetter: StdIOWrapping,
        xcodeChecker: XcodeChecker
    ) {
        self.logsOutputTypeSetter = logsOutputTypeSetter
        self.bufferSetter = bufferSetter
        self.xcodeChecker = xcodeChecker
    }

    private func setupConsoleInteractionParams() {
        // Make our stdout unbuffered.
        bufferSetter.setupbuf(stdoutp: __stdoutp, wtf: nil)

        // Force Rainbow to output colors.
        if !xcodeChecker.isRunningFromXcode {
            logsOutputTypeSetter.outputTarget = .console
        }
    }

    public func run<T: ParsableCommand>(_: T.Type, arguments: [String]? = nil) {
        setupConsoleInteractionParams()

        T.main(arguments)
    }
}

public extension RootCommandRunner {
    convenience init() {
        self.init(
            logsOutputTypeSetter: Rainbow.self,
            bufferSetter: StdIOWrapper(),
            xcodeChecker: XcodeChecker()
        )
    }
}
