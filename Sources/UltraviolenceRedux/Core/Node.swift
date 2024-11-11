internal final class Node {
    weak var graph: Graph?
    var children: [Node] = []
    var needsRebuild = true
    var renderPass: BuiltinRenderPass?
    var previousRenderPass: Any?
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
        renderPass?._buildNodeTree(self)
    }

    func setNeedsRebuild() {
        needsRebuild = true
    }
}

internal extension Node {
    @MainActor
    func dump(depth: Int = 0) {
        let indent = String(repeating: "  ", count: depth)

        if let renderPass = renderPass as? AnyBuiltinRenderPass {
            print("\(indent)\(String(describing: renderPass.renderPassType))")
        }
        else if let renderPass {
            print("\(indent)\(String(describing: renderPass))")
        }
        else {
            print("\(indent)<nil>")
        }

        for child in children {
            child.dump(depth: depth + 1)
        }
    }
}
