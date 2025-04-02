internal import os
import UltraviolenceSupport

// TODO: #24 Make Internal
public class Graph {
    internal var activeNodeStack: [Node] = []
    public private(set) var root: Node
    internal var signpostID = signposter?.makeSignpostID()

    @MainActor
    public init<Content>(content: Content) throws where Content: Element {
        root = Node()
        root.graph = self
        root.element = content
    }

    @MainActor
    public func update<Content>(content: Content) throws where Content: Element {
        try withIntervalSignpost(signposter, name: "Graph.updateContent()", id: signpostID) {
            // TODO: #25 We need to somehow detect if the content has changed.
            let saved = Self.current
            Self.current = self
            defer {
                Self.current = saved
            }
            try content.expandNode(root, context: .init())
        }
    }

    @MainActor
    // TODO: #149 `rebuildIfNeeded` is no longer being called. Which is worrying.
    internal func rebuildIfNeeded() throws {
        let saved = Self.current
        Self.current = self
        defer {
            Self.current = saved
        }
        guard let rootElement = root.element else {
            preconditionFailure("Root element is missing.")
        }
        try rootElement.expandNode(root, context: .init())
    }

    private static let _current = OSAllocatedUnfairLock<Graph?>(uncheckedState: nil)

    internal static var current: Graph? {
        get {
            _current.withLockUnchecked { $0 }
        }
        set {
            _current.withLockUnchecked { $0 = newValue }
        }
    }

    internal func makeNode() -> Node {
        Node(graph: self)
    }
}
