@MainActor
internal protocol BodylessElement: Element where Body == Never {
    // TODO: This should be renamed. And it should be differently named than Node.buildNodeTree.
    func _expandNode(_ node: Node, depth: Int) throws

    func _enter(_ node: Node, environment: inout UVEnvironmentValues) throws
    func _exit(_ node: Node, environment: UVEnvironmentValues) throws
}

extension BodylessElement {
    func _enter(_ node: Node, environment: inout UVEnvironmentValues) throws {
        // This line intentionally left blank.
    }

    func _exit(_ node: Node, environment: UVEnvironmentValues) throws {
        // This line intentionally left blank.
    }
}
