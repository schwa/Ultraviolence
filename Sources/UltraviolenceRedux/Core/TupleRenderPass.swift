public struct TuplePass <each T: RenderPass>: RenderPass {
    public typealias Body = Never

    private let children: (repeat each T)

    public init(_ children: repeat each T) {
        self.children = (repeat each children)
    }
}

extension TuplePass: BuiltinRenderPass {
    func _buildNodeTree(_ parent: Node) {
        var idx = 0
        for child in repeat (each children) {
            let child = AnyBuiltinRenderPass(child)
            if parent.children.count <= idx {
                parent.children.append(Node(graph: parent.graph))
            }
            child._buildNodeTree(parent.children[idx])
            idx += 1
        }
    }
}
