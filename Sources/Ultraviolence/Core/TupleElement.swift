public struct TupleElement <each T: Element>: Element {
    public typealias Body = Never

    private let children: (repeat each T)

    public init(_ children: repeat each T) {
        self.children = (repeat each children)
    }
}

extension TupleElement: BodylessElement {
    internal func visitChildrenBodyless(_ visit: (any Element) throws -> Void) rethrows {
        for child in repeat (each children) {
            try visit(child)
        }
    }
}
