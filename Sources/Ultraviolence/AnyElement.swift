public struct AnyElement: Element, BodylessElement {
    private let base: Any
    private let expand: (Node, Int) throws -> Void

    public init(_ base: some Element) {
        self.base = base
        expand = { node, depth in
            try base.expandNode(node, depth: depth)
        }
    }

    internal func _expandNode(_ node: Node, depth: Int) throws {
        guard let graph = node.graph else {
            preconditionFailure("Cannot build node tree without a graph.")
        }
        if node.children.isEmpty {
            node.children.append(graph.makeNode())
        }
        try expand(node.children[0], depth + 1)
    }
}

public extension Element {
    func eraseToAnyElement() -> AnyElement {
        AnyElement(self)
    }
}
