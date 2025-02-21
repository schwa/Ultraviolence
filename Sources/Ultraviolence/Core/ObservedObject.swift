import Combine

internal protocol AnyObservedObject {
    @MainActor
    func addDependency(_ node: Node)
}

// MARK: -

@propertyWrapper
public struct ObservedObject<ObjectType: ObservableObject> {
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

extension ObservedObject: Equatable {
    public static func == (l: ObservedObject, r: ObservedObject) -> Bool {
        l.wrappedValue === r.wrappedValue
    }
}

extension ObservedObject: AnyObservedObject {
    func addDependency(_ node: Node) {
        _object.addDependency(node)
    }
}

// MARK: -

@propertyWrapper
private final class ObservedObjectBox<Wrapped: ObservableObject> {
    private let wrappedValue: Wrapped
    private var cancellable: AnyCancellable?
    private weak var node: Node?

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
            node.setNeedsRebuild()
        }
    }
}

// MARK: -

@dynamicMemberLookup
public struct ProjectedValue <ObjectType: ObservableObject> {
    private var observedObject: ObservedObject<ObjectType>

    internal init(_ observedObject: ObservedObject<ObjectType>) {
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
