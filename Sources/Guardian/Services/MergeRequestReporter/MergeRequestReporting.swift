//

// sourcery: AutoMockable
public protocol MergeRequestReporting {
    func createOrUpdateReport() throws

    func warn(_ markdown: String)

    func fail(_ markdown: String)

    func message(_ markdown: String)

    func markdown(_ markdown: String)

    func success(_ markdown: String)

    func hasFails() -> Bool
}
