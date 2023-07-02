//

import ArgumentParser
import Foundation
import Guardian
import Simulator
import SwiftlaneCore
import Yams

public protocol SwiftlaneCommand: ParsableCommand {
    var commonOptions: CommonOptions { get }

    func runCMD() throws
}

public extension SwiftlaneCommand {
    func run() throws {
        DependenciesFactory.registerLoggerProducer(commons: commonOptions)
        DependenciesFactory.registerProducers()

        CommonRunner(logger: DependenciesFactory.resolve()).run {
            try runCMD()
        }
    }
}
