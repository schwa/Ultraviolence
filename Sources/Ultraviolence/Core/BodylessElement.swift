@MainActor
internal protocol BodylessElement {
    func expandIntoNode(_ node: Node, context: ExpansionContext) throws

    func visitChildrenBodyless(_ visit: (any Element) throws -> Void) throws

    func setupEnter(_ node: Node) throws
    func setupExit(_ node: Node) throws

    func workloadEnter(_ node: Node) throws
    func workloadExit(_ node: Node) throws
}

internal extension BodylessElement {
    func visitChildrenBodyless(_ visit: (any Element) throws -> Void) rethrows {
        // Default implementation - most BodylessElements have no children
    }

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
