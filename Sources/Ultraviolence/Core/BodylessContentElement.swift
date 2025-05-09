internal protocol BodylessContentElement: BodylessElement {
    associatedtype Content: Element

    var content: Content { get }
}

extension BodylessContentElement {
    func expandNodeHelper(_ node: Node, context: ExpansionContext) throws {
        let graph = try node.graph.orThrow(.noCurrentGraph)
        if node.children.isEmpty {
            node.children.append(graph.makeNode())
        }
        try content.expandNode(node.children[0], context: context.deeper())
    }

    func _expandNode(_ node: Node, context: ExpansionContext) throws {
        try expandNodeHelper(node, context: context)
    }
}

internal struct ExpansionContext {
    var depth: Int

    init(depth: Int = 0) {
        self.depth = depth
    }
}

internal extension ExpansionContext {
    func deeper() -> ExpansionContext {
        ExpansionContext(depth: depth + 1)
    }
}
