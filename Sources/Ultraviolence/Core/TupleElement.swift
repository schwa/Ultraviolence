public struct TupleElement <each T: Element>: Element {
    public typealias Body = Never

    private let children: (repeat each T)

    public init(_ children: repeat each T) {
        self.children = (repeat each children)
    }
}

extension TupleElement: BodylessElement {
    internal func expandIntoNode(_ node: Node, context: ExpansionContext) throws {
        let graph = try node.graph.orThrow(.noCurrentGraph)
        var index = 0
        for child in repeat (each children) {
            if node.children.count <= index {
                node.children.append(graph.makeNode())
            }
            try child.expandNode(node.children[index], context: context.deeper())
            index += 1
        }
    }

    internal func visitChildrenBodyless(_ visit: (any Element) throws -> Void) rethrows {
        for child in repeat (each children) {
            try visit(child)
        }
    }
}
