@MainActor
internal protocol BodylessRenderPass: RenderPass where Body == Never {
    // TODO: This should be renamed. And it should be differently named than Node.buildNodeTree.
    func _expandNode(_ node: Node) throws

    func _enter(_ node: Node) throws
    func _exit(_ node: Node) throws
}

extension BodylessRenderPass {
    func _enter(_ node: Node) throws {
        // This line intentionally left blank.
    }

    func _exit(_ node: Node) throws {
        // This line intentionally left blank.
    }
}
