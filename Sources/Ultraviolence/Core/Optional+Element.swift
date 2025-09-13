extension Optional: Element, BodylessElement where Wrapped: Element {
    public typealias Body = Never

    internal func visitChildrenBodyless(_ visit: (any Element) throws -> Void) rethrows {
        try self.map { try visit($0) }
    }
}
