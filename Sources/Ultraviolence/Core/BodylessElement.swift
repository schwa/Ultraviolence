@MainActor
internal protocol BodylessElement {
    // TODO: #12 This should be renamed. And it should be differently named than Node.buildNodeTree.
    func _expandNode(_ node: Node, context: ExpansionContext) throws

    func setupEnter(_ node: Node) throws
    func setupExit(_ node: Node) throws

    func workloadEnter(_ node: Node) throws
    func workloadExit(_ node: Node) throws
}

internal extension BodylessElement {
    func setupEnter(_ node: Node) throws {
        // This line intentionally left blank.
    }

    func setupExit(_ node: Node) throws {
        // This line intentionally left blank.
    }

    func workloadEnter(_ node: Node) throws {
        // This line intentionally left blank.
    }

    func workloadExit(_ node: Node) throws {
        // This line intentionally left blank.
    }
}
