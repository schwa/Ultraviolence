import Combine

internal protocol AnyObservedObject {
    @MainActor
    func addDependency(_ node: Node)
}

// MARK: -

@propertyWrapper
public struct UVObservedObject<ObjectType: ObservableObject> {
    @ObservedObjectBox
    private var object: ObjectType

    public init(wrappedValue: ObjectType) {
        _object = ObservedObjectBox(wrappedValue)
    }

    public var wrappedValue: ObjectType {
        object
    }

    public var projectedValue: ProjectedValue<ObjectType> {
        .init(self)
    }
}

extension UVObservedObject: Equatable {
    public static func == (l: UVObservedObject, r: UVObservedObject) -> Bool {
        l.wrappedValue === r.wrappedValue
    }
}

extension UVObservedObject: AnyObservedObject {
    internal func addDependency(_ node: Node) {
        _object.addDependency(node)
    }
}

// MARK: -

@propertyWrapper
private final class ObservedObjectBox<Wrapped: ObservableObject> {
    let wrappedValue: Wrapped
    var cancellable: AnyCancellable?
    weak var node: Node?

    init(_ wrappedValue: Wrapped) {
        self.wrappedValue = wrappedValue
    }

    @MainActor
    func addDependency(_ node: Node) {
        guard node !== self.node else {
            return
        }
        self.node = node
        cancellable = wrappedValue.objectWillChange.sink { _ in
            node.system?.dirtyIdentifiers.insert(node.id)
        }
    }
}

// MARK: -

@dynamicMemberLookup
public struct ProjectedValue <ObjectType: ObservableObject> {
    private var observedObject: UVObservedObject<ObjectType>

    internal init(_ observedObject: UVObservedObject<ObjectType>) {
        self.observedObject = observedObject
    }

    public subscript<Value>(dynamicMember keyPath: ReferenceWritableKeyPath<ObjectType, Value>) -> UVBinding<Value> {
        UVBinding(get: {
            observedObject.wrappedValue[keyPath: keyPath]
        }, set: { newValue in
            observedObject.wrappedValue[keyPath: keyPath] = newValue
        })
    }
}
