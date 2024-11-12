internal import os

public class Graph {
    var activeNodeStack: [Node] = []

    private(set) var root: Node

    @MainActor
    public init<Content>(content: Content) where Content: View {
        root = Node()
        root.graph = self
        Self.current = self
        content.expandNode(root)
        Self.current = nil
    }

    @MainActor
    func rebuildIfNeeded() {
        let saved = Self.current
        Self.current = self
        defer {
            Self.current = saved
        }
        guard let rootView = root.view else {
            fatalError("Root view is missing.")
        }
        rootView.expandNode(root)
    }

    static let _current = OSAllocatedUnfairLock<Graph?>(uncheckedState: nil)

    static var current: Graph? {
        get {
            _current.withLockUnchecked { $0 }
        }
        set {
            _current.withLockUnchecked { $0 = newValue }
        }
    }

    func makeNode() -> Node {
        Node(graph: self)
    }
}

public extension Graph {
    @MainActor
    func dump() {
        root.dump()
    }
}
