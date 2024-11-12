extension Optional: RenderPass, BuiltinRenderPass where Wrapped: RenderPass {
    public typealias Body = Never

    func _buildNodeTree(_ parent: Node) {
        map(AnyBuiltinRenderPass.init)?._buildNodeTree(parent)
    }
}
