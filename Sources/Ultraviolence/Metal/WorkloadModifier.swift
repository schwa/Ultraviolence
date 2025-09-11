internal struct WorkloadModifier <Content>: Element, BodylessElement, BodylessContentElement where Content: Element {
    var content: Content
    var _workloadEnter: ((UVEnvironmentValues) throws -> Void)?

    init(content: Content, workloadEnter: ((UVEnvironmentValues) throws -> Void)? = nil) {
        self.content = content
        self._workloadEnter = workloadEnter
    }

    func system_workloadEnter(_ node: NeoNode) throws {
        try _workloadEnter?(node.environmentValues)
    }
}

public extension Element {
    func onWorkloadEnter(_ action: @escaping (UVEnvironmentValues) throws -> Void) -> some Element {
        WorkloadModifier(content: self, workloadEnter: action)
    }
}
