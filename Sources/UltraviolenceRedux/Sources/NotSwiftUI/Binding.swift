internal import Foundation

@propertyWrapper
public struct Binding<Value>: Equatable {
    private let get: () -> Value
    private let set: (Value) -> ()
    private let id = UUID()

    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        self.get = get
        self.set = set
    }

    public var wrappedValue: Value {
        get { get() }
        nonmutating set { set(newValue) }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
