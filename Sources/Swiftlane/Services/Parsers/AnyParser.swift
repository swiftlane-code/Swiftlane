//

public struct AnyParser<T>: Parsing {
    public private(set) var _parse: (String) throws -> T

    public init<V: Parsing>(_ delegatee: V) where V.ResultType == T {
        _parse = delegatee.parse
    }

    public func parse(from: String) throws -> T {
        try _parse(from)
    }
}
