extension Optional: RenderPass, BodylessRenderPass where Wrapped: RenderPass {
    public typealias Body = Never

    func _expandNode(_ node: Node) {
        self?.expandNode(node)
    }
}
