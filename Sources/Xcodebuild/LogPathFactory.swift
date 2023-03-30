//

import Foundation
import SwiftlaneCore

private extension String {
    var replaceSpaces: String {
        replacingOccurrences(of: " ", with: "_")
    }
}

public class LogPathFactory {
    let filesManager: FSManaging
    let dateFormatter: DateFormatter

    init(
        filesManager: FSManaging,
        dateFormatter: DateFormatter
    ) {
        self.filesManager = filesManager
        self.dateFormatter = dateFormatter
    }

    private var date: String {
        dateFormatter.string(from: Date())
    }

    public let buildLogsDirName = try! RelativePath("build")
    public let archiveLogsDirName = try! RelativePath("archive")
    public let testRunLogsDirName = try! RelativePath("test")
    public let systemLogsDirName = try! RelativePath("system")

    public static let stderrLogFileNamePrefix = "stderr_"

    public typealias LogsPathPair = (stdout: AbsolutePath, stderr: AbsolutePath)

    private func makeStdOutAndStdErrFileName(baseName: String) -> (stdout: RelativePath, stderr: RelativePath) {
        (
            try! RelativePath(baseName),
            try! RelativePath(Self.stderrLogFileNamePrefix + baseName)
        )
    }

    private func makeStdOutAndStdErrPaths(in dir: AbsolutePath, baseName: String) -> LogsPathPair {
        let fileNames = makeStdOutAndStdErrFileName(baseName: baseName)
        return (
            dir.appending(path: fileNames.stdout),
            dir.appending(path: fileNames.stderr)
        )
    }

    public func makeBuildLogPath(logsDir: AbsolutePath, scheme: String) -> LogsPathPair {
        let result = makeStdOutAndStdErrPaths(
            in: logsDir.appending(path: buildLogsDirName),
            baseName: scheme + "_\(date).log"
        )
        try! filesManager.mkdir(result.stdout.deletingLastComponent)
        try! filesManager.mkdir(result.stderr.deletingLastComponent)
        return result
    }

    public func makeArchiveLogPath(logsDir: AbsolutePath, scheme: String, configuration: String) -> LogsPathPair {
        let result = makeStdOutAndStdErrPaths(
            in: logsDir.appending(path: archiveLogsDirName),
            baseName: scheme + "_\(configuration)_\(date).log"
        )
        try! filesManager.mkdir(result.stdout.deletingLastComponent)
        try! filesManager.mkdir(result.stderr.deletingLastComponent)
        return result
    }

    public func makeTestRunLogPath(logsDir: AbsolutePath, scheme: String, simulatorName: String) -> LogsPathPair {
        let result = makeStdOutAndStdErrPaths(
            in: logsDir.appending(path: testRunLogsDirName),
            baseName: "\(scheme) \(simulatorName) \(date).log".replaceSpaces
        )
        try! filesManager.mkdir(result.stdout.deletingLastComponent)
        try! filesManager.mkdir(result.stderr.deletingLastComponent)
        return result
    }

    public func makeJunitReportPath(logsDir: AbsolutePath, scheme: String, simulatorName: String) -> AbsolutePath {
        let result = logsDir
            .appending(path: testRunLogsDirName)
            .appending(path: try! RelativePath("\(scheme) \(simulatorName) \(date).junit".replaceSpaces))
        try! filesManager.mkdir(result.deletingLastComponent)
        return result
    }

    public func makeSystemLogPath(logsDir: AbsolutePath, scheme: String, simulatorName: String) -> AbsolutePath {
        let result = logsDir
            .appending(path: systemLogsDirName)
            .appending(path: try! RelativePath("\(scheme) \(simulatorName) \(date).log".replaceSpaces))
        try! filesManager.mkdir(result.deletingLastComponent)
        return result
    }
}

public extension LogPathFactory {
    convenience init(filesManager: FSManaging) {
        // TODO: Use formatter from one of predefined statically allocated formatters.
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy_HH-mm-ss.SSS"

        self.init(
            filesManager: filesManager,
            dateFormatter: formatter
        )
    }
}
