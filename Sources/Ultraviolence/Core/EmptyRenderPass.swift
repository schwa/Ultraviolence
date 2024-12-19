public struct EmptyRenderPass: RenderPass {
    public typealias Body = Never

    public init() {
        // This line intentionally left blank.
    }
}

extension EmptyRenderPass: BodylessRenderPass {
    func _expandNode(_ node: Node) throws {
        // This line intentionally left blank.
    }
}
