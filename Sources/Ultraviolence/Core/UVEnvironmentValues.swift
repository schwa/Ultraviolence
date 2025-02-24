public struct UVEnvironmentValues {
    struct Key: Hashable, CustomDebugStringConvertible {
        var id: ObjectIdentifier // TODO: We don't need to store this. But AnyIdentifgier gets a tad upset.
        var value: Any.Type
    }

    class Storage {
        weak var parent: Storage?
        var values: [Key: Any] = [:]
    }

    var storage = Storage()

    internal mutating func merge(_ parent: Self) {
        guard parent.storage !== self.storage else {
            // TODO: Use a precondition instead.
            logger?.warning("Parent and child are the same.")
            return
        }
        //        precondition(parent.storage !== self.storage)
        storage.parent = parent.storage
    }
}

public protocol UVEnvironmentKey {
    associatedtype Value
    static var defaultValue: Value { get }
}

public extension UVEnvironmentValues {
    subscript<Key: UVEnvironmentKey>(key: Key.Type) -> Key.Value {
        get {
            if let value = storage.get(.init(key)) as? Key.Value {
                return value
            }
            return Key.defaultValue
        }
        set {
            // TODO: Use isKnownUniquelyReferenced.
            storage.values[.init(key)] = newValue
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

    private var keyPath: KeyPath<UVEnvironmentValues, Value>

    public init(_ keyPath: KeyPath<UVEnvironmentValues, Value>) {
        self.keyPath = keyPath
    }
}

extension UVEnvironmentValues.Key {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }

    init<K: UVEnvironmentKey>(_ key: K.Type) {
        id = ObjectIdentifier(key)
        value = key
    }

    var debugDescription: String {
        "\(value)"
    }
}

extension UVEnvironmentValues.Storage {
    // TODO: Replace with subscript.
    func get(_ key: UVEnvironmentValues.Key) -> Any? {
        if let value = values[key] {
            return value
        }
        if let parent, let value = parent.get(key) {
            return value
        }
        return nil
    }
}

extension UVEnvironmentValues.Storage: CustomDebugStringConvertible {
    public var debugDescription: String {
        let keys = values.map { "\($0.key)".trimmingPrefix("__Key_") }.sorted()
        return "([\(keys.joined(separator: ", "))], parent: \(parent != nil)))"
    }
}

extension UVEnvironmentValues: CustomDebugStringConvertible {
    public var debugDescription: String {
        "(storage: \(storage.debugDescription))"
    }
}
