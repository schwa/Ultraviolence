internal struct AnyBodylessElement: Element, BodylessElement {
    fileprivate var _setupEnter: ((NeoNode) throws -> Void)?
    fileprivate var _setupExit: ((NeoNode) throws -> Void)?
    fileprivate var _workloadEnter: ((NeoNode) throws -> Void)?
    fileprivate var _workloadExit: ((NeoNode) throws -> Void)?

    init() {
        // This line intentionally left blank
    }

    func system_configureNodeBodyless(_ node: NeoNode) throws {
        // This line intentionally left blank
    }
    
    func system_setupEnter(_ node: NeoNode) throws {
        try _setupEnter?(node)
    }
    
    func system_setupExit(_ node: NeoNode) throws {
        try _setupExit?(node)
    }
    
    func system_workloadEnter(_ node: NeoNode) throws {
        try _workloadEnter?(node)
    }
    
    func system_workloadExit(_ node: NeoNode) throws {
        try _workloadExit?(node)
    }
}

// TODO: I am not sure why these are here exactly?
internal extension AnyBodylessElement {
    func onSetupEnter(_ action: @escaping (NeoNode) throws -> Void) -> AnyBodylessElement {
        var modifier = self
        modifier._setupEnter = action
        return modifier
    }
    
    func onSetupEnter(_ action: @escaping () throws -> Void) -> AnyBodylessElement {
        var modifier = self
        modifier._setupEnter = { _ in try action() }
        return modifier
    }
    
    func onSetupExit(_ action: @escaping (NeoNode) throws -> Void) -> AnyBodylessElement { // periphery:ignore
        var modifier = self
        modifier._setupExit = action
        return modifier
    }
    
    func onSetupExit(_ action: @escaping () throws -> Void) -> AnyBodylessElement { // periphery:ignore
        var modifier = self
        modifier._setupExit = { _ in try action() }
        return modifier
    }
    
    func onWorkloadEnter(_ action: @escaping (NeoNode) throws -> Void) -> AnyBodylessElement {
        var modifier = self
        modifier._workloadEnter = action
        return modifier
    }
    
    func onWorkloadEnter(_ action: @escaping () throws -> Void) -> AnyBodylessElement {
        var modifier = self
        modifier._workloadEnter = { _ in try action() }
        return modifier
    }
    
    func onWorkloadExit(_ action: @escaping (NeoNode) throws -> Void) -> AnyBodylessElement { // periphery:ignore
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
