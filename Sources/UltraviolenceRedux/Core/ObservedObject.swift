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
fileprivate final class ObservedObjectBox<Wrapped: ObservableObject> {
    fileprivate let wrappedValue: Wrapped
    private var cancellable: AnyCancellable?
    private weak var node: Node?

    init(_ wrappedValue: Wrapped) {
        self.wrappedValue = wrappedValue
    }

    @MainActor
    func addDependency(_ node: Node) {
        if node === self.node { return }
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

    fileprivate init(_ observedObject: ObservedObject<ObjectType>) {
        self.observedObject = observedObject
    }

    public subscript<Value>(dynamicMember keyPath: ReferenceWritableKeyPath<ObjectType, Value>) -> Binding<Value> {
        Binding(get: {
            observedObject.wrappedValue[keyPath: keyPath]
        }, set: {
            observedObject.wrappedValue[keyPath: keyPath] = $0
        })
    }
}
