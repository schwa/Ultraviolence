internal import os

// TODO: Make Internal #https://github.com/schwa/Ultraviolence/issues/24
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
        // TODO: We need to somehow detect if the content has changed. https://github.com/schwa/Ultraviolence/issues/25
        Self.current = self
        try content.expandNode(root, context: .init())
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
