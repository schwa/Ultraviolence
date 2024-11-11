public struct EmptyRenderPass: RenderPass {
    public typealias Body = Never

    public init() {
        // This line intentionally left blank.
    }
}

extension EmptyRenderPass: BuiltinRenderPass {
    func _buildNodeTree(_ node: Node) {
        // This line intentionally left blank.
    }
}
