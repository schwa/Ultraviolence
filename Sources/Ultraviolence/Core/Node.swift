internal final class Node {
    weak var graph: Graph?
    var children: [Node] = []
    var needsRebuild = true
    var element: (any Element)?
    var previousElement: (any Element)?
    var stateProperties: [String: Any] = [:]
    var environmentValues = UVEnvironmentValues()

    init() {
        // This line intentionally left blank.
    }

    init(graph: Graph?) {
        assert(graph != nil)
        self.graph = graph
    }

    @MainActor
    func rebuildIfNeeded() throws {
        try element?.expandNode(self, depth: 0)
    }

    func setNeedsRebuild() {
        needsRebuild = true
    }
}
