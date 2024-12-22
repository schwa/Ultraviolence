@MainActor
internal protocol BodylessElement: Element where Body == Never {
    // TODO: This should be renamed. And it should be differently named than Node.buildNodeTree.
    func _expandNode(_ node: Node) throws

    func _enter(_ node: Node, environment: inout EnvironmentValues) throws
    func _exit(_ node: Node, environment: EnvironmentValues) throws
}

extension BodylessElement {
    func _enter(_ node: Node, environment: inout EnvironmentValues) throws {
        // This line intentionally left blank.
    }

    func _exit(_ node: Node, environment: EnvironmentValues) throws {
        // This line intentionally left blank.
    }
}
