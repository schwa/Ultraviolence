/// Contain a value with-in a reference type.
@propertyWrapper
internal final class Box<Wrapped> {
    var wrappedValue: Wrapped

    init(_ erappedValue: Wrapped) {
        self.wrappedValue = erappedValue
    }
}
