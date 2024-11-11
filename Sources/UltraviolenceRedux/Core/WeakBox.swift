/// A box for holding a weak reference to an object.
internal final class WeakBox<Wrapped: AnyObject> {
    internal weak var wrappedValue: Wrapped?
    internal init(_ wrapped: Wrapped) {
        self.wrappedValue = wrapped
    }
}

internal extension WeakBox {
    func callAsFunction() -> Wrapped? {
        wrappedValue
    }
}
