public struct TupleRenderPass <each T: RenderPass>: RenderPass {
    public typealias Body = Never

    private let children: (repeat each T)

    public init(_ children: repeat each T) {
        self.children = (repeat each children)
    }
}

extension TupleRenderPass: BodylessRenderPass {
    func _expandNode(_ node: Node) {
        guard let graph = node.graph else {
            fatalError("Cannot build node tree without a graph.")
        }
        var index = 0
        for child in repeat (each children) {
            if node.children.count <= index {
                node.children.append(graph.makeNode())
            }
            child.expandNode(node.children[index])
            index += 1
        }
    }
}
