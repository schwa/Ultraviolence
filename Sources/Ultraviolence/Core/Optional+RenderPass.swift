extension Optional: RenderPass, BodylessRenderPass where Wrapped: RenderPass {
    public typealias Body = Never

    func _expandNode(_ node: Node) throws {
        try self?.expandNode(node)
    }
}
