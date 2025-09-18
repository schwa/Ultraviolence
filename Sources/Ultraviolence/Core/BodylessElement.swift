@MainActor
internal protocol BodylessElement {
    func visitChildrenBodyless(_ visit: (any Element) throws -> Void) throws

    func configureNodeBodyless(_ node: Node) throws
    func setupEnter(_ node: Node) throws
    func setupExit(_ node: Node) throws
    func workloadEnter(_ node: Node) throws
    func workloadExit(_ node: Node) throws

    /// Returns true if the change from `old` to `self` requires the setup phase to run again.
    /// This is a SHALLOW check - only considers this element, not its children.
    nonisolated func requiresSetup(comparedTo old: Self) -> Bool
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

extension BodylessElement {
    nonisolated func requiresSetup(comparedTo old: Self) -> Bool {
        // Default: use Equatable if available, otherwise assume change requires setup
        if let self = self as? any Equatable,
           let old = old as? any Equatable {
            return !isEqual(self, old)
        }
        return true
    }
}

extension BodylessElement where Self: Equatable {
    nonisolated func requiresSetup(comparedTo old: Self) -> Bool {
        self != old
    }
}
