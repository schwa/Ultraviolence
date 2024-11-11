extension Optional: RenderPass, BuiltinRenderPass where Wrapped: RenderPass {
    public typealias Body = Never

    func _buildNodeTree(_ node: Node) {
        map(AnyBuiltinRenderPass.init)?._buildNodeTree(node)
    }
}
