@MainActor
internal protocol BodylessElement {
    func visitChildrenBodyless(_ visit: (any Element) throws -> Void) throws

    func system_configureNodeBodyless(_ node: NeoNode) throws
    func system_setupEnter(_ node: NeoNode) throws
    func system_setupExit(_ node: NeoNode) throws
    func system_workloadEnter(_ node: NeoNode) throws
    func system_workloadExit(_ node: NeoNode) throws
}

extension BodylessElement {
    func visitChildrenBodyless(_ visit: (any Element) throws -> Void) throws {
        // This line intentionally left blank.
    }

    func system_configureNodeBodyless(_ node: NeoNode) throws {
        // This line intentionally left blank.
    }
    
    func system_setupEnter(_ node: NeoNode) throws {
        // This line intentionally left blank.
    }
    func system_setupExit(_ node: NeoNode) throws {
        // This line intentionally left blank.
    }
    func system_workloadEnter(_ node: NeoNode) throws {
        // This line intentionally left blank.
    }
    func system_workloadExit(_ node: NeoNode) throws {
        // This line intentionally left blank.
    }
}
