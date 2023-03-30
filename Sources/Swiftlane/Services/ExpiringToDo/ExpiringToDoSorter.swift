//

import Foundation

public protocol ExpiringToDoSorting {
    func sort(todos: [VerifiedExpiringTodoModel]) -> [VerifiedExpiringTodoModel]
}

public class ExpiringToDoSorter: ExpiringToDoSorting {
    public func sort(todos: [VerifiedExpiringTodoModel]) -> [VerifiedExpiringTodoModel] {
        let otherToDos = todos.filter {
            if case .approachingExpiryDate = $0.status {
                return false
            }
            return true
        }

        /// Sort approaching todos by `daysLeft` before reporting.
        let approachingToDos = todos
            .compactMap { todo -> (VerifiedExpiringTodoModel, daysLeft: UInt)? in
                if case let .approachingExpiryDate(daysLeft) = todo.status {
                    return (todo, daysLeft: daysLeft)
                }
                return nil
            }
            .sorted { lhs, rhs in
                lhs.daysLeft < rhs.daysLeft
            }
            .map(\.0)

        return otherToDos + approachingToDos
    }
}
