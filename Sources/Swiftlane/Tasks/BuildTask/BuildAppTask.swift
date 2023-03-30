//

import Foundation
import Xcodebuild

public final class BuildAppTask {
    private let builder: BuilderProtocol

    private let buildForTesting: Bool
    private let destination: BuildDestination

    public init(
        builder: BuilderProtocol,
        buildForTesting: Bool,
        destination: BuildDestination
    ) {
        self.builder = builder
        self.buildForTesting = buildForTesting
        self.destination = destination
    }

    public func run() throws {
        try builder.build(forTesting: buildForTesting, destination: destination)
    }
}
