internal struct AnyBodylessElement: Element, BodylessElement {
    fileprivate var _setupEnter: (() throws -> Void)?
    fileprivate var _setupExit: (() throws -> Void)?
    fileprivate var _workloadEnter: (() throws -> Void)?
    fileprivate var _workloadExit: (() throws -> Void)?

    init() {
        // This line intentionally left blank
    }

    func expandIntoNode(_: Node, context: ExpansionContext) throws {
        // This line intentionally left blank.
    }

    func setupEnter(_: Node) throws {
        try _setupEnter?()
    }

    func setupExit(_: Node) throws {
        try _setupExit?()
    }

    func workloadEnter(_: Node) throws {
        try _workloadEnter?()
    }

    func workloadExit(_: Node) throws {
        try _workloadExit?()
    }
}

internal extension AnyBodylessElement {
    func onSetupEnter(_ action: @escaping () throws -> Void) -> AnyBodylessElement {
        var modifier = self
        modifier._setupEnter = action
        return modifier
    }
    func onSetupExit(_ action: @escaping () throws -> Void) -> AnyBodylessElement { // periphery:ignore
        var modifier = self
        modifier._setupExit = action
        return modifier
    }
    func onWorkloadEnter(_ action: @escaping () throws -> Void) -> AnyBodylessElement {
        var modifier = self
        modifier._workloadEnter = action
        return modifier
    }
    func onWorkloadExit(_ action: @escaping () throws -> Void) -> AnyBodylessElement { // periphery:ignore
        var modifier = self
        modifier._workloadExit = action
        return modifier
    }
}
