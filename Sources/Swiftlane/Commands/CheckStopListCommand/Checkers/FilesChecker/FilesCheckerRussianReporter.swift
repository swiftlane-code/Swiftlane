
import Foundation
import Guardian

// sourcery: AutoMockable
public protocol FilesCheckerReporting {
    func reportSuccess()
    func reportFailsDetected(_ fails: [FilesChecker.BadFileInfo])
}

public class FilesCheckerRussianReporter {
    private let reporter: MergeRequestReporting

    public init(
        reporter: MergeRequestReporting
    ) {
        self.reporter = reporter
    }
}

extension FilesCheckerRussianReporter: FilesCheckerReporting {
    public func reportSuccess() {
        reporter.success("Запрещенных файлов и изменений не найдено")
    }

    public func reportFailsDetected(_ fails: [FilesChecker.BadFileInfo]) {
        fails
            .map {
                "У вас обнаружена контрабанда: изменения в файле `\($0.file)`"
            }
            .forEach {
                reporter.fail($0)
            }
    }
}
