//

import Foundation

public protocol PeripheryResultsFormatting {
    func format(results: [PeripheryModels.ScanResult]) throws -> String
}
