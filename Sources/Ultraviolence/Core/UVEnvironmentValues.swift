public struct UVEnvironmentValues {
    struct Key: Hashable, CustomDebugStringConvertible {
        var id: ObjectIdentifier
        var value: Any.Type
    }

    class Storage {
        weak var parent: Storage? {
            didSet {
                // Check for cycles when setting parent
                if let parent {
                    var visited = Set<ObjectIdentifier>()
                    visited.insert(ObjectIdentifier(self))
                    
                    var path: [ObjectIdentifier] = [ObjectIdentifier(self)]
                    var current: Storage? = parent
                    while let node = current {
                        let id = ObjectIdentifier(node)
                        if visited.contains(id) {
                            // Build a string showing the cycle
                            path.append(id)
                            let cycleDescription = path.map { "\($0)" }.joined(separator: " -> ")
                            assertionFailure("Cannot set parent - would create a cycle in Storage chain: \(cycleDescription)")
                            // Clear the parent to prevent the cycle
                            self.parent = nil
                            return
                        }
                        visited.insert(id)
                        path.append(id)
                        current = node.parent
                    }
                }
            }
        }
        var values: [Key: Any] = [:]
    }

    var storage = Storage()

    internal mutating func merge(_ parent: Self) {
        precondition(parent.storage !== self.storage, "Cannot merge storage with itself")
        
        // Debug: Check if we're about to create a problematic parent relationship
        if storage.parent === parent.storage {
            print("Warning: Attempting to merge with the same parent again (no-op)")
            return
        }
        
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
            if let value = storage[.init(key)] as? Key.Value {
                return value
            }
            return Key.defaultValue
        }
        set {
            if !isKnownUniquelyReferenced(&storage) {
                let newStorage = Storage()
                newStorage.parent = storage.parent
                newStorage.values = storage.values
                storage = newStorage
            }
            storage.values[.init(key)] = newValue
        }
    }
}

// TODO: #30 Make into actual modifier.
internal struct EnvironmentWritingModifier<Content: Element>: Element, BodylessElement {
    var content: Content
    var modify: (inout UVEnvironmentValues) -> Void

    func expandIntoNode(_ node: Node, context: ExpansionContext) throws {
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

    func expandIntoNode(_ node: Node, context: ExpansionContext) throws {
        let value = node.environmentValues[keyPath: keyPath]
        try content(value).expandNode(node, context: context.deeper())
    }
}

// MARK: -

@propertyWrapper
public struct UVEnvironment <Value> {
    public var wrappedValue: Value {
        guard let graph = ElementGraph.current else {
            preconditionFailure("Environment must be used within a ElementGraph.")
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
    subscript(key: UVEnvironmentValues.Key) -> Any? {
        if let value = values[key] {
            return value
        }
        // TODO: #76 Parent chain should never have cycles due to didSet check
        if let parent, let value = parent[key] {
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
