//

import Foundation
import Guardian
import SwiftlaneCore

public protocol FilePathReporting {
    func reportInvalidFilePath(_ path: String)
}

public class FilePathReporter {
    private let reporter: MergeRequestReporting

    public init(
        reporter: MergeRequestReporting
    ) {
        self.reporter = reporter
    }
}

extension FilePathReporter: FilePathReporting {
    public func reportInvalidFilePath(_ path: String) {
        reporter.fail("Путь к файлу содержит запрещённые символы `\(path)`")
    }
}
