public struct UVEnvironmentValues {
    struct Key: Hashable, CustomDebugStringConvertible {
        var id: ObjectIdentifier // TODO: #49 We don't need to store this. But AnyIdentifgier gets a tad upset.
        var value: Any.Type
    }

    class Storage {
        weak var parent: Storage?
        var values: [Key: Any] = [:]
    }

    var storage = Storage()

    internal mutating func merge(_ parent: Self) {
        precondition(parent.storage !== self.storage)
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
            // TODO: #26 Use isKnownUniquelyReferenced.
            storage.values[.init(key)] = newValue
        }
    }
}

// TODO: #30 Make into actual modifier.
internal struct EnvironmentWritingModifier<Content: Element>: Element, BodylessElement {
    var content: Content
    var modify: (inout UVEnvironmentValues) -> Void

    func _expandNode(_ node: Node, context: ExpansionContext) throws {
        modify(&node.environmentValues)
        try content.expandNode(node, context: context.deeper())
    }
}

public extension Element {
    func environment<Value>(_ keyPath: WritableKeyPath<UVEnvironmentValues, Value>, _ value: Value) -> some Element {
        EnvironmentWritingModifier(content: self) { environmentValues in
            environmentValues[keyPath: keyPath] = value
        }
    }
}

// MARK: -

public struct EnvironmentReader<Value, Content: Element>: Element, BodylessElement {
    var keyPath: KeyPath<UVEnvironmentValues, Value>
    var content: (Value) throws -> Content

    public init(keyPath: KeyPath<UVEnvironmentValues, Value>, @ElementBuilder content: @escaping (Value) throws -> Content) {
        self.keyPath = keyPath
        self.content = content
    }

    func _expandNode(_ node: Node, context: ExpansionContext) throws {
        let value = node.environmentValues[keyPath: keyPath]
        try content(value).expandNode(node, context: context.deeper())
    }
}

// TODO: #50 SwiftUI.Environment adopts DynamicProperty.
// public protocol DynamicProperty {
//    mutating func update()
// }
//
// extension DynamicProperty {
//    public mutating func update()
// }

// MARK: -

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

// MARK: -

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
    // TODO: #115 Replace with subscript.
    func get(_ key: UVEnvironmentValues.Key) -> Any? {
        if let value = values[key] {
            return value
        }
        // TODO: #76 This can infinite loop if there is a cycle. *WHY* is there a cycle.
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
