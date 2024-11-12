/// A type-erased RenderPass wrapper that converts a RenderPass to a BuiltinRenderPass.
internal struct AnyBuiltinRenderPass: BuiltinRenderPass {
    @MainActor
    var renderPassType: Any

    private var buildNodeTree: (Node) -> ()


    @MainActor
    init<V: RenderPass>(_ renderPass: V) {
        renderPassType = type(of: renderPass)
        buildNodeTree = renderPass.buildNodeTree(_:)
    }

    @MainActor
    func _buildNodeTree(_ parent: Node) {
        buildNodeTree(parent)
    }
}

extension AnyBuiltinRenderPass: @preconcurrency CustomDebugStringConvertible {
    var debugDescription: String {
        "AnyBuiltinRenderPass(\(renderPassType))"
    }
}
