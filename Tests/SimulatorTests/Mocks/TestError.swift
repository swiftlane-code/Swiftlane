//

enum TestError: Error {
    case some
    case another
    case etc
}

extension TestError: Equatable {}
