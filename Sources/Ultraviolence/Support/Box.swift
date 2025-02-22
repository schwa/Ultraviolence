/// Contain a value with-in a reference type.
@propertyWrapper
internal final class Box<Wrapped> {
    internal var wrappedValue: Wrapped

    internal init(_ erappedValue: Wrapped) {
        self.wrappedValue = erappedValue
    }
}
