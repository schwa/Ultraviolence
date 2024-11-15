@MainActor
internal protocol BodylessRenderPass {
    // TODO: This should be renamed. And it should be differently named than Node.buildNodeTree.
    func _expandNode(_ node: Node)

    func _setup(_ node: Node)
}

extension BodylessRenderPass {
    func _setup(_ node: Node) {
        // This line intentionally left blank.
    }
}
