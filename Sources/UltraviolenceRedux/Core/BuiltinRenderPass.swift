@MainActor
internal protocol BuiltinRenderPass {
    func _buildNodeTree(_ parent: Node)

    func _setup(_ node: Node)
    func _encoder(_ node: Node)
}

extension BuiltinRenderPass {
    func _setup(_ node: Node) {
        // This line intentionally left blank.
    }
    func _encoder(_ node: Node) {
        // This line intentionally left blank.
    }
}
