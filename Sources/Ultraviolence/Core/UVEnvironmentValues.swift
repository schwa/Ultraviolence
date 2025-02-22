public struct UVEnvironmentValues {
    struct Key: Hashable, CustomDebugStringConvertible {
        var id: ObjectIdentifier // TODO: We don't need to store this. But AnyIdentifgier gets a tad upset.
        var value: Any.Type

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            id.hash(into: &hasher)
        }

        init<K: EnvironmentKey>(_ key: K.Type) {
            id = ObjectIdentifier(key)
            value = key
        }

        var debugDescription: String {
            "\(value)"
        }
    }

    internal var values: [Key: Any] = [:]

    internal mutating func merge(_ other: Self) {
        values.merge(other.values) { _, new in new }
    }
}

public protocol EnvironmentKey {
    associatedtype Value
    static var defaultValue: Value { get }
}

public extension UVEnvironmentValues {
    subscript<Key: EnvironmentKey>(key: Key.Type) -> Key.Value {
        get {
            guard let value = values[.init(key), default: Key.defaultValue] as? Key.Value else {
                preconditionFailure("Could not cast value.")
            }
            return value
        }
        set {
            values[.init(key)] = newValue
        }
    }
}

internal struct EnvironmentWritingModifier<Content: Element>: Element, BodylessElement {
    var content: Content
    var modify: (inout UVEnvironmentValues) -> Void

    func _expandNode(_ node: Node, depth: Int) throws {
        modify(&node.environmentValues)
        try content.expandNode(node, depth: depth + 1)
    }
}

public extension Element {
    func environment<Value>(_ keyPath: WritableKeyPath<UVEnvironmentValues, Value>, _ value: Value) -> some Element {
        EnvironmentWritingModifier(content: self) { environmentValues in
            environmentValues[keyPath: keyPath] = value
        }
    }
}

public struct EnvironmentReader<Value, Content: Element>: Element, BodylessElement {
    var keyPath: KeyPath<UVEnvironmentValues, Value>
    var content: (Value) -> Content

    public init(keyPath: KeyPath<UVEnvironmentValues, Value>, content: @escaping (Value) -> Content) {
        self.keyPath = keyPath
        self.content = content
    }

    func _expandNode(_ node: Node, depth: Int) throws {
        let value = node.environmentValues[keyPath: keyPath]
        try content(value).expandNode(node, depth: depth + 1)
    }
}

// TODO: SwiftUI.Environment adopts DynamicProperty.
// public protocol DynamicProperty {
//    mutating func update()
// }
//
// extension DynamicProperty {
//    public mutating func update()
// }

@propertyWrapper
public struct UVEnvironment <Value> {
    public var wrappedValue: Value {
        guard let graph = Graph.current else {
            preconditionFailure("Environment must be used within a Graph.")
        }
        guard let currentNode = graph.activeNodeStack.last else {
            preconditionFailure("Environment must be used within a Node.")
        }
        return currentNode.environmentValues[keyPath: keyPath]
    }

    var keyPath: KeyPath<UVEnvironmentValues, Value>

    public init(_ keyPath: KeyPath<UVEnvironmentValues, Value>) {
        self.keyPath = keyPath
    }
}
