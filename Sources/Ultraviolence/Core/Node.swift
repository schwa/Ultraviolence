public final class Node {
    weak var graph: ElementGraph?
    weak var parent: Node?
    public internal(set) var children: [Node] = []
    var needsRebuild = true
    public internal(set) var element: (any Element)?
    var previousElement: (any Element)?
    public internal(set) var stateProperties: [String: Any] = [:]
    var environmentValues = UVEnvironmentValues()
    public internal(set) var debugLabel: String?

    init() {
        // This line intentionally left blank.
    }

    init(graph: ElementGraph?) {
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
