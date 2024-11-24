@MainActor
internal protocol BodylessRenderPass: RenderPass where Body == Never {
    // TODO: This should be renamed. And it should be differently named than Node.buildNodeTree.
    func _expandNode(_ node: Node)

    func drawEnter()
    func drawExit()

    func _setup(_ node: Node)
}

extension BodylessRenderPass {
    func _setup(_ node: Node) {
        // This line intentionally left blank.
    }

    func drawEnter() {
        // This line intentionally left blank.

    }
    func drawExit() {
        // This line intentionally left blank.

    }
}
