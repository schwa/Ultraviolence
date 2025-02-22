// TODO: Rename
internal protocol FoobarElement: BodylessElement {
    associatedtype Content: Element

    var content: Content { get }
}

extension FoobarElement {
    func _expandNode(_ node: Node, depth: Int) throws {
        guard let graph = node.graph else {
            preconditionFailure("Cannot build node tree without a graph.")
        }
        if node.children.isEmpty {
            node.children.append(graph.makeNode())
        }
        try content.expandNode(node.children[0], depth: depth + 1)
    }
}
