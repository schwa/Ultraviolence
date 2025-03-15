internal import os

// TODO: #24 Make Internal
public class Graph {
    internal var activeNodeStack: [Node] = []
    public private(set) var root: Node

    @MainActor
    public init<Content>(content: Content) throws where Content: Element {
        root = Node()
        root.graph = self
        root.element = content
    }

    @MainActor
    public func updateContent<Content>(content: Content) throws where Content: Element {
        // TODO: #25 We need to somehow detect if the content has changed.
        let saved = Self.current
        Self.current = self
        defer {
            Self.current = saved
        }
        try content.expandNode(root, context: .init())
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

public extension Graph {
    @MainActor
    func dump() throws {
        var s = ""
        try dump(to: &s)
        print(s, terminator: "")
    }

    @MainActor
    func dump(to output: inout some TextOutputStream) throws {
        try visit { depth, node in
            let element = node.element
            let indent = String(repeating: "  ", count: depth)
            if let element {
                let typeName = String(describing: type(of: element)).split(separator: "<").first ?? ""
                print("\(indent)\(typeName): \(node.environmentValues)", terminator: "", to: &output)
                print("", to: &output)
            }
            else {
                print("\(indent)<no element!>", to: &output)
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
