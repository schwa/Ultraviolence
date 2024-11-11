public struct TupleRenderPass <each T: RenderPass>: RenderPass {
    public typealias Body = Never

    private let children: (repeat each T)

    public init(_ children: repeat each T) {
        self.children = (repeat each children)
    }
}

extension TupleRenderPass: BuiltinRenderPass {
    func _buildNodeTree(_ node: Node) {
        var idx = 0
        for child in repeat (each children) {
            let child = AnyBuiltinRenderPass(child)
            if node.children.count <= idx {
                node.children.append(Node(graph: node.graph))
            }
            child._buildNodeTree(node.children[idx])
            idx += 1
        }
    }
}
