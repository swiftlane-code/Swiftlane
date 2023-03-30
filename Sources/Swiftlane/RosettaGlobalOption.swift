//

import ArgumentParser

public struct RosettaGlobalOption: ParsableArguments {
    @Flag(
        name: [.customLong("use-rosetta")],
        help: "Use Rosetta for xcodebuild."
    )
    public var isUseRosetta = false

    public init() {}
}
