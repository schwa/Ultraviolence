public struct EnvironmentValues {
    private var values: [ObjectIdentifier: Any] = [:]
}

public protocol EnvironmentKey {
    associatedtype Value
    static var defaultValue: Value { get }
}

public extension EnvironmentValues {
    subscript<Key: EnvironmentKey>(key: Key.Type) -> Key.Value {
        get {
            guard let value = values[ObjectIdentifier(key), default: Key.defaultValue] as? Key.Value else {
                fatalError("Could not cast value.")
            }
            return value
        }
        set {
            values[ObjectIdentifier(key)] = newValue
        }
    }
}

struct EnvironmentWritingModifier<Content: View>: View, BuiltinView {
    var content: Content
    var modify: (inout EnvironmentValues) -> ()

    func _buildNodeTree(_ node: Node) {
        modify(&node.environmentValues)
        AnyBuiltinView(content)._buildNodeTree(node)
    }
}

public extension View {
    func environment<Value>(_ keyPath: WritableKeyPath<EnvironmentValues, Value>, _ value: Value) -> some View {
        EnvironmentWritingModifier(content: self) { environmentValues in
            environmentValues[keyPath: keyPath] = value
        }
    }
}

public struct EnvironmentReader<Value, Content: View>: View, BuiltinView {
    var keyPath: KeyPath<EnvironmentValues, Value>
    var content: (Value) -> Content

    public init(keyPath: KeyPath<EnvironmentValues, Value>, content: @escaping (Value) -> Content) {
        self.keyPath = keyPath
        self.content = content
    }

    func _buildNodeTree(_ node: Node) {
        let value = node.environmentValues[keyPath: keyPath]
        AnyBuiltinView(content(value))._buildNodeTree(node)
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
public struct Environment <Value> {
    public var wrappedValue: Value {
        get {
            guard let graph = Graph.current else {
                fatalError("Environment must be used within a Graph.")
            }
            guard let currentNode = graph.activeNodeStack.last else {
                fatalError("Environment must be used within a Node.")
            }
            return currentNode.environmentValues[keyPath: keyPath]
        }
    }

    var keyPath: KeyPath<EnvironmentValues, Value>

    public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
        self.keyPath = keyPath
    }
}
