public struct EmptyElement: Element {
    public typealias Body = Never

    public init() {
        // This line intentionally left blank.
    }
}

extension EmptyElement: BodylessElement {
    func visitChildrenBodyless(_ visit: (any Element) throws -> Void) throws {
        // This line intentionally left blank.
    }
}
