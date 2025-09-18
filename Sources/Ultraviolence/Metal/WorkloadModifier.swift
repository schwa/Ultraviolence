internal struct WorkloadModifier <Content>: Element, BodylessElement, BodylessContentElement where Content: Element {
    var content: Content
    var _workloadEnter: ((UVEnvironmentValues) throws -> Void)?

    init(content: Content, workloadEnter: ((UVEnvironmentValues) throws -> Void)? = nil) {
        self.content = content
        self._workloadEnter = workloadEnter
    }

    func workloadEnter(_ node: Node) throws {
        try _workloadEnter?(node.environmentValues)
    }

    nonisolated func requiresSetup(comparedTo old: WorkloadModifier<Content>) -> Bool {
        // WorkloadModifier only affects the workload phase, never requires setup
        false
    }
}

public extension Element {
    func onWorkloadEnter(_ action: @escaping (UVEnvironmentValues) throws -> Void) -> some Element {
        WorkloadModifier(content: self, workloadEnter: action)
    }
}
