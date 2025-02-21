public struct TupleElement <each T: Element>: Element {
    public typealias Body = Never

    private let children: (repeat each T)

    public init(_ children: repeat each T) {
        self.children = (repeat each children)
    }
}

extension TupleElement: BodylessElement {
    func _expandNode(_ node: Node) throws {
        guard let graph = node.graph else {
            preconditionFailure("Cannot build node tree without a graph.")
        }
        var index = 0
        for child in repeat (each children) {
            if node.children.count <= index {
                node.children.append(graph.makeNode())
            }
            try child.expandNode(node.children[index])
            index += 1
        }
    }
}
