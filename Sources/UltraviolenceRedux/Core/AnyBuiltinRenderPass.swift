/// A type-erased RenderPass wrapper that converts a RenderPass to a BuiltinRenderPass.
internal struct AnyBuiltinRenderPass: BuiltinRenderPass {
    private var buildNodeTree: (Node) -> ()

    @MainActor
    var renderPassType: Any

    @MainActor
    init<V: RenderPass>(_ renderPass: V) {
        buildNodeTree = renderPass.buildNodeTree(_:)
        renderPassType = type(of: renderPass)
    }

    @MainActor
    func _buildNodeTree(_ node: Node) {
        buildNodeTree(node)
    }
}

extension AnyBuiltinRenderPass: @preconcurrency CustomDebugStringConvertible {
    var debugDescription: String {
        "AnyBuiltinRenderPass(\(renderPassType))"
    }
}
