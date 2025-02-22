internal extension Graph {
    @MainActor
    func visit(_ visitor: (Int, Node) throws -> Void, enter: (Node) throws -> Void = { _ in }, exit: (Node) throws -> Void = { _ in }) throws {
        let saved = Graph.current
        Graph.current = self
        defer {
            Graph.current = saved
        }

        try root.rebuildIfNeeded()

        assert(activeNodeStack.isEmpty)

        try root.visit(visitor) { node in
            activeNodeStack.append(node)
            try enter(node)
        }
        exit: { node in
            try exit(node)
            activeNodeStack.removeLast()
        }
    }
}

internal extension Node {
    func visit(depth: Int = 0, _ visitor: (Int, Node) throws -> Void, enter: (Node) throws -> Void = { _ in }, exit: (Node) throws -> Void = { _ in }) rethrows {
        try enter(self)
        try visitor(depth, self)
        try children.forEach { child in
            try child.visit(depth: depth + 1, visitor, enter: enter, exit: exit)
        }
        try exit(self)
    }
}
