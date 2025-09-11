// TODO: is this still needed?
public struct AnyElement: Element, BodylessElement {
    private let base: any Element
    
    public init(_ base: some Element) {
        self.base = base
    }

    func visitChildrenBodyless(_ visit: (any Element) throws -> Void) throws {
        try visit(base)
    }
}

public extension Element {
    func eraseToAnyElement() -> AnyElement {
        AnyElement(self)
    }
}
