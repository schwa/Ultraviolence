@MainActor
internal protocol BodylessView {
    // TODO: This should be renamed. And it should be differently named than Node.buildNodeTree.
    func _expandNode(_ node: Node)
}
