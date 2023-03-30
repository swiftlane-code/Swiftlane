
import Foundation
import Guardian

// sourcery: AutoMockable
public protocol FilesCheckerReporting {
    func reportSuccess()
    func reportFailsDetected(_ fails: [FilesChecker.BadFileInfo])
}

public class FilesCheckerEnReporter {
    private let reporter: MergeRequestReporting

    public init(
        reporter: MergeRequestReporting
    ) {
        self.reporter = reporter
    }
}

extension FilesCheckerEnReporter: FilesCheckerReporting {
    public func reportSuccess() {
        reporter.success("No banned files or changes found")
    }

    public func reportFailsDetected(_ fails: [FilesChecker.BadFileInfo]) {
        fails
            .map {
                "You have detected contraband: changes in the file `\($0.file)`"
            }
            .forEach {
                reporter.fail($0)
            }
    }
}
