// internal extension NodeGraph {
//    @MainActor
//    func visit(enter: (Node) throws -> Void, exit: (Node) throws -> Void) throws {
//        // swiftlint:disable:next no_empty_block
//        try visit({ _, _ in }, enter: enter, exit: exit)
//    }
//
//    @MainActor
//    func visit(_ visitor: (Int, Node) throws -> Void, enter: (Node) throws -> Void, exit: (Node) throws -> Void) throws {
//        let saved = NodeGraph.current
//        NodeGraph.current = self
//        defer {
//            NodeGraph.current = saved
//        }
//
//        try root.rebuildIfNeeded()
//
//        assert(activeNodeStack.isEmpty)
//
//        try root.visit(visitor) { node in
//            activeNodeStack.append(node)
//            try enter(node)
//        }
//        exit: { node in
//            try exit(node)
//            activeNodeStack.removeLast()
//        }
//    }
// }
//
// internal extension Node {
//    func visit(depth: Int = 0, _ visitor: (Int, Node) throws -> Void) rethrows {
//        // swiftlint:disable:next no_empty_block
//        try visit(depth: depth, visitor, enter: { _ in }, exit: { _ in })
//    }
//
//    func visit(depth: Int = 0, _ visitor: (Int, Node) throws -> Void, enter: (Node) throws -> Void, exit: (Node) throws -> Void) rethrows {
//        try enter(self)
//        try visitor(depth, self)
//        try children.forEach { child in
//            try child.visit(depth: depth + 1, visitor, enter: enter, exit: exit)
//        }
//        try exit(self)
//    }
// }
