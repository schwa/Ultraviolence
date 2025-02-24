@MainActor
internal protocol BodylessElement: Element where Body == Never {
    // TODO: This should be renamed. And it should be differently named than Node.buildNodeTree.
    func _expandNode(_ node: Node, depth: Int) throws

    func workloadEnter(_ node: Node, environment: inout UVEnvironmentValues) throws
    func workloadExit(_ node: Node, environment: UVEnvironmentValues) throws
}

internal extension BodylessElement {
    func workloadEnter(_ node: Node, environment: inout UVEnvironmentValues) throws {
        // This line intentionally left blank.
    }

    func workloadExit(_ node: Node, environment: UVEnvironmentValues) throws {
        // This line intentionally left blank.
    }
}
