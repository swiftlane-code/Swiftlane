//

import Foundation

// sourcery: AutoMockable
public protocol RangesWelding {
    /// [1,2,3,5,8,9] -> ["1...3", "5", "8...9"]
    func weldRanges<T: SignedInteger>(from numbers: [T]) -> [String]
}

public class RangesWelder: RangesWelding {
    private class Range<T: SignedInteger>: CustomStringConvertible {
        public var start: T
        public var end: T

        public init(start: T) {
            self.start = start
            end = start
        }

        public var description: String {
            start == end ? "\(start)" : "\(start)...\(end)"
        }
    }

    public init() {}

    /// [1,2,3,5,8,9] -> ["1...3", "5", "8...9"]
    public func weldRanges<T: SignedInteger>(from numbers: [T]) -> [String] {
        var ranges = [Range<T>]()

        numbers.forEach { line in
            if ranges.last?.end == line - 1 {
                ranges.last?.end = line
            } else {
                ranges.append(Range(start: line))
            }
        }

        return ranges.map(\.description)
    }
}
