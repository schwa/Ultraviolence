public struct AnyElement: Element, BodylessElement {
    private let expand: (Node, ExpansionContext) throws -> Void

    public init(_ base: some Element) {
        expand = { node, context in
            try base.expandNode(node, context: context)
        }
    }

    internal func expandIntoNode(_ node: Node, context: ExpansionContext) throws {
        let graph = try node.graph.orThrow(.noCurrentGraph)
        if node.children.isEmpty {
            node.children.append(graph.makeNode())
        }
        try expand(node.children[0], context.deeper())
    }
}

public extension Element {
    func eraseToAnyElement() -> AnyElement {
        AnyElement(self)
    }
}
