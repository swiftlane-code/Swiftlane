//

import Foundation

import SwiftlaneCore

public struct SimulatorCloner {
    public let original: SimulatorProtocol
    let simulatorProvider: SimulatorProviding
    let timeMeasurer: TimeMeasuring

    public init(
        original: SimulatorProtocol,
        simulatorProvider: SimulatorProviding,
        timeMeasurer: TimeMeasuring
    ) {
        self.original = original
        self.simulatorProvider = simulatorProvider
        self.timeMeasurer = timeMeasurer
    }

    public func deleteAllClones() {
        timeMeasurer.measure(description: "Deleting clones") {
            try? simulatorProvider.getAllDevices()
                .filter { $0.device.name.contains("Clone") }
                .forEach { try $0.deleteSimulator() }
        }
    }

    private func makeClone(_ index: UInt, eraseExisting: Bool, eraseNewlyCloned: Bool) throws -> Simulator {
        let name = original.device.name + " Swiftlane Clone \(index)"

        guard let existing = try simulatorProvider.getAllDevices().first(where: { $0.device.name == name }) else {
            return try original.clone(withName: name, andErase: eraseNewlyCloned)
        }

        if existing.runtime != original.runtime {
            try existing.deleteSimulator()
            return try original.clone(withName: name, andErase: eraseNewlyCloned)
        }

        if eraseExisting { try existing.erase() }
        return existing
    }

    /// Prepare required of simulators.
    /// - Parameters:
    ///   - count: required count of sims.
    ///   - preboot: boot all prepared simulators. When `true` it saves time on waiting for sims to boot up after tests are already built.
    ///   - eraseExisting: if existing simulators should be erased.
    ///   - eraseNewlyCloned: if newly cloned simulators should be erased.
    public func makeClones(count: UInt, preboot: Bool, eraseExisting: Bool, eraseNewlyCloned: Bool) throws -> [Simulator] {
        try timeMeasurer.measure(description: "Cloning simulators") {
            let clones = try (0 ..< count).map {
                try makeClone($0, eraseExisting: eraseExisting, eraseNewlyCloned: eraseNewlyCloned)
            }

            if preboot {
                clones.forEach { try? $0.boot() }
            }

            return clones
        }
    }
}
