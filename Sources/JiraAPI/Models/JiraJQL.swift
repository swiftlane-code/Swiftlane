
import Foundation

public final class JiraJQL {
    public var jqlString: String

    public init(projectKey: String) {
        jqlString = "project = \(projectKey)"
    }

    public init(jqlString: String) {
        self.jqlString = jqlString
    }
}

public extension JiraJQL {
    @discardableResult
    func status<T: CustomStringConvertible>(in statuses: [T]) -> JiraJQL {
        jqlString += " AND status in (" + statuses.map(\.description).joined(separator: ", ") + ")"
        return self
    }

    @discardableResult
    func version(_ version: String) -> JiraJQL {
        jqlString += " AND fixVersion = \(version)"
        return self
    }

    @discardableResult
    func type<T: CustomStringConvertible>(in types: [T]) -> JiraJQL {
        jqlString += " AND type in (" + types.map(\.description).joined(separator: ", ") + ")"
        return self
    }

    @discardableResult
    func labels(_ label: String) -> JiraJQL {
        jqlString += " AND labels = \(label)"
        return self
    }
}
