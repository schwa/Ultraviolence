import UltraviolenceSupport

public struct EnvironmentDumper: Element, BodylessElement {
    @UVEnvironment(\.self)
    var environment

    func _expandNode(_ node: Node) throws {
        print(environment)
    }
}

extension Graph {
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

extension Node {
    func visit(depth: Int = 0, _ visitor: (Int, Node) throws -> Void, enter: (Node) throws -> Void = { _ in }, exit: (Node) throws -> Void = { _ in }) rethrows {
        try enter(self)
        try visitor(depth, self)
        try children.forEach { child in
            try child.visit(depth: depth + 1, visitor, enter: enter, exit: exit)
        }
        try exit(self)
    }
}

extension Element {
    var shortDescription: String {
        "\(type(of: self))"
    }
}

extension UltraviolenceError {
    static func missingEnvironment(_ key: PartialKeyPath<EnvironmentValues>) -> Self {
        missingEnvironment("\(key)")
    }
}

internal struct IdentifiableBox <Key, Value>: Identifiable where Key: Hashable {
    var id: Key
    var value: Value
}

internal extension IdentifiableBox where Key == ObjectIdentifier, Value: AnyObject {
    init(_ value: Value) {
        self.id = ObjectIdentifier(value)
        self.value = value
    }
}

extension Element {
    func _dump() throws {
        let graph = try Graph(content: self)
        graph.dump()
    }
}

@MainActor
extension Node {
    var shortDescription: String {
        self.element?.shortDescription ?? "<empty>"
    }
}
