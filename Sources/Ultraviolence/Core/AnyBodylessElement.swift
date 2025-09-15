internal struct AnyBodylessElement: Element, BodylessElement {
    fileprivate var _setupEnter: ((Node) throws -> Void)?
    fileprivate var _setupExit: ((Node) throws -> Void)?
    fileprivate var _workloadEnter: ((Node) throws -> Void)?
    fileprivate var _workloadExit: ((Node) throws -> Void)?

    init() {
        // This line intentionally left blank
    }

    func configureNodeBodyless(_ node: Node) throws {
        // This line intentionally left blank
    }

    func setupEnter(_ node: Node) throws {
        try _setupEnter?(node)
    }

    func setupExit(_ node: Node) throws {
        try _setupExit?(node)
    }

    func workloadEnter(_ node: Node) throws {
        try _workloadEnter?(node)
    }

    func workloadExit(_ node: Node) throws {
        try _workloadExit?(node)
    }

    nonisolated func requiresSetup(comparedTo old: AnyBodylessElement) -> Bool {
        // AnyBodylessElement wraps closures - if the closures change, we need setup
        // Since we can't compare closures, always return true for safety
        return true
    }
}

// TODO: #225 Clarify purpose of these modifier-style extensions - may be for builder pattern or phase-specific actions
internal extension AnyBodylessElement {
    func onSetupEnter(_ action: @escaping (Node) throws -> Void) -> AnyBodylessElement {
        var modifier = self
        modifier._setupEnter = action
        return modifier
    }

    func onSetupEnter(_ action: @escaping () throws -> Void) -> AnyBodylessElement {
        var modifier = self
        modifier._setupEnter = { _ in try action() }
        return modifier
    }

    func onSetupExit(_ action: @escaping (Node) throws -> Void) -> AnyBodylessElement { // periphery:ignore
        var modifier = self
        modifier._setupExit = action
        return modifier
    }

    func onSetupExit(_ action: @escaping () throws -> Void) -> AnyBodylessElement { // periphery:ignore
        var modifier = self
        modifier._setupExit = { _ in try action() }
        return modifier
    }

    func onWorkloadEnter(_ action: @escaping (Node) throws -> Void) -> AnyBodylessElement {
        var modifier = self
        modifier._workloadEnter = action
        return modifier
    }

    func onWorkloadEnter(_ action: @escaping () throws -> Void) -> AnyBodylessElement {
        var modifier = self
        modifier._workloadEnter = { _ in try action() }
        return modifier
    }

    func onWorkloadExit(_ action: @escaping (Node) throws -> Void) -> AnyBodylessElement { // periphery:ignore
        var modifier = self
        modifier._workloadExit = action
        return modifier
    }

    func onWorkloadExit(_ action: @escaping () throws -> Void) -> AnyBodylessElement { // periphery:ignore
        var modifier = self
        modifier._workloadExit = { _ in try action() }
        return modifier
    }
}
