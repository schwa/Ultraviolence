@MainActor
internal protocol BodylessElement: Element where Body == Never {
    // TODO: This should be renamed. And it should be differently named than Node.buildNodeTree.
    func _expandNode(_ node: Node, depth: Int) throws

    func workloadEnter(_ node: Node) throws
    func workloadExit(_ node: Node) throws
}

internal extension BodylessElement {
    func workloadEnter(_ node: Node) throws {
        // This line intentionally left blank.
    }

    func workloadExit(_ node: Node) throws {
        // This line intentionally left blank.
    }
}
