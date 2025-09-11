extension Optional: Element, BodylessElement where Wrapped: Element {
    public typealias Body = Never

    internal func visitChildrenBodyless(_ visit: (any Element) throws -> Void) rethrows {
        // swiftlint:disable:next shorthand_optional_binding
        if let wrapped = self {
            try visit(wrapped)
        }
    }
}
