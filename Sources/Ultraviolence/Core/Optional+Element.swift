extension Optional: Element, BodylessElement where Wrapped: Element {
    public typealias Body = Never

    internal func expandIntoNode(_ node: Node, context: ExpansionContext) throws {
        try self?.expandNode(node, context: context.deeper())
    }
    
    internal func visitChildrenBodyless(_ visit: (any Element) throws -> Void) rethrows {
        if let wrapped = self {
            try visit(wrapped)
        }
    }
}
