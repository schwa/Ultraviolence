internal import os

internal class Graph {
    var activeNodeStack: [Node] = []

    private(set) var root: Node

    @MainActor
    init<Content>(content: Content) where Content: RenderPass {
        root = Node()
        root.graph = self
        Self.current = self
        content.buildNodeTree(root)
        Self.current = nil
    }

    @MainActor
    func rebuildIfNeeded() {
        let saved = Self.current
        Self.current = self
        defer {
            Self.current = saved
        }
        guard let rootRenderPass = root.renderPass else {
            fatalError("Root renderPass is missing.")
        }
        rootRenderPass._buildNodeTree(root)
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
}

extension Graph {
    @MainActor
    func dump() {
        root.dump()
    }
}
