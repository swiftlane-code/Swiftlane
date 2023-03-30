//

import Foundation

extension ProgressUserInfoKey {
    // This key is not even mentioned in Apple's docs but it exists...
    static var byteCompletedCountKey: ProgressUserInfoKey {
        ProgressUserInfoKey(rawValue: "NSProgressByteCompletedCountKey")
    }

    // This key is not even mentioned in Apple's docs but it exists...
    static var byteTotalCountKey: ProgressUserInfoKey {
        ProgressUserInfoKey(rawValue: "NSProgressByteTotalCountKey")
    }
}
