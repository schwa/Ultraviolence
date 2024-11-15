internal final class Node {
    weak var graph: Graph?
    var children: [Node] = []
    var needsRebuild = true
    var renderPass: (any RenderPass)?
    var previousRenderPass: (any RenderPass)?
    var stateProperties: [String: Any] = [:]
    var environmentValues = EnvironmentValues()

    init() {
    }

    init(graph: Graph?) {
        assert(graph != nil)
        self.graph = graph
    }

    @MainActor
    func rebuildIfNeeded() {
        renderPass?.expandNode(self)
    }

    func setNeedsRebuild() {
        needsRebuild = true
    }
}
