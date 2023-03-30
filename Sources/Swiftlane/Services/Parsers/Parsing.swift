//

// sourcery: AutoMockable
// sourcery: associatedtype = "ResultType"
public protocol Parsing {
    associatedtype ResultType

    func parse(from description: String) throws -> ResultType
}
