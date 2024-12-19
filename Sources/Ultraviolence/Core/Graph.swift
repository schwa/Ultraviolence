internal import os

public class Graph {
    var activeNodeStack: [Node] = []

    private(set) var root: Node

    @MainActor
    public init<Content>(content: Content) throws where Content: RenderPass {
        root = Node()
        root.graph = self
        Self.current = self
        try content.expandNode(root)
        Self.current = nil
    }

    @MainActor
    func rebuildIfNeeded() throws {
        let saved = Self.current
        Self.current = self
        defer {
            Self.current = saved
        }
        guard let rootRenderPass = root.renderPass else {
            fatalError("Root renderPass is missing.")
        }
        try rootRenderPass.expandNode(root)
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
            let renderPass = node.renderPass
            let indent = String(repeating: "  ", count: depth)
            if let renderPass {
                let typeName = String(describing: type(of: renderPass))
                print("\(indent)\(typeName)", terminator: "")
                print(" [Env: \(node.environmentValues.values.count)]", terminator: "")
                print("")
            }
            else {
                print("\(indent)<no renderPass!>")
            }
        }
    }
}
