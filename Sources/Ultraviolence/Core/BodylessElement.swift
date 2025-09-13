@MainActor
internal protocol BodylessElement {
    func visitChildrenBodyless(_ visit: (any Element) throws -> Void) throws

    func configureNodeBodyless(_ node: Node) throws
    func setupEnter(_ node: Node) throws
    func setupExit(_ node: Node) throws
    func workloadEnter(_ node: Node) throws
    func workloadExit(_ node: Node) throws
}

extension BodylessElement {
    func visitChildrenBodyless(_ visit: (any Element) throws -> Void) throws {
        // This line intentionally left blank.
    }

    func configureNodeBodyless(_ node: Node) throws {
        // This line intentionally left blank.
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
