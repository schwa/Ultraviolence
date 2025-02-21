internal import os

public class Graph {
    var activeNodeStack: [Node] = []

    private(set) var root: Node

    @MainActor
    public init<Content>(content: Content) throws where Content: Element {
        root = Node()
        root.graph = self
        Self.current = self
        try content.expandNode(root, depth: 0)
        Self.current = nil
    }

    @MainActor
    func updateContent<Content>(content: Content) throws where Content: Element {
        Self.current = self
        try content.expandNode(root, depth: 0)
        Self.current = nil
    }

    @MainActor
    func rebuildIfNeeded() throws {
        logger?.log("\(type(of: self)).\(#function)")
        let saved = Self.current
        Self.current = self
        defer {
            Self.current = saved
        }
        guard let rootElement = root.element else {
            preconditionFailure("Root element is missing.")
        }
        try rootElement.expandNode(root, depth: 0)
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
        // swiftlint:disable:next force_try
        try! visit { depth, node in
            let element = node.element
            let indent = String(repeating: "  ", count: depth)
            if let element {
                let typeName = String(describing: type(of: element))
                print("\(indent)\(typeName)", terminator: "")
                print(" [Env: \(node.environmentValues.values.count)]", terminator: "")
                print("")
            }
            else {
                print("\(indent)<no element!>")
            }
        }
    }
}
