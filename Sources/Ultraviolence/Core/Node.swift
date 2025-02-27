internal final class Node {
    weak var graph: Graph?
    weak var parent: Node?
    var children: [Node] = []
    var needsRebuild = true
    var element: (any Element)?
    var previousElement: (any Element)?
    var stateProperties: [String: Any] = [:]
    var environmentValues = UVEnvironmentValues()
    var debugLabel: String?

    init() {
        // This line intentionally left blank.
    }

    init(graph: Graph?) {
        assert(graph != nil)
        self.graph = graph
    }

    @MainActor
    func rebuildIfNeeded() throws {
        try element?.expandNode(self, context: .init())
    }

    func setNeedsRebuild() {
        needsRebuild = true
    }
}
