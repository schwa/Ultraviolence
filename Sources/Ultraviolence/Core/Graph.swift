internal import os

// TODO: Make Internal
public class Graph {
    internal var activeNodeStack: [Node] = []
    private(set) var root: Node

    @MainActor
    public init<Content>(content: Content) throws where Content: Element {
        root = Node()
        root.graph = self
        root.element = content
    }

    @MainActor
    internal func updateContent<Content>(content: Content) throws where Content: Element {
        Self.current = self
        try content.expandNode(root, depth: 0)
        Self.current = nil
    }

    @MainActor
    internal func rebuildIfNeeded() throws {
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

public extension Graph {
    @MainActor
    func dump() throws {
        try visit { depth, node in
            let element = node.element
            let indent = String(repeating: "  ", count: depth)
            if let element {
                let typeName = String(describing: type(of: element)).split(separator: "<").first ?? ""
                print("\(indent)\(typeName): \(node.environmentValues)", terminator: "")
                print("")
            }
            else {
                print("\(indent)<no element!>")
            }
        }
        enter: { _ in
            // This line intentionally left blank.
        }
        exit: { _ in
            // This line intentionally left blank.
        }
    }
}
