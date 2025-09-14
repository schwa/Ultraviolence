// TODO: #219 Organize these Element extensions into logical groups or separate files for better maintainability

internal extension Element {
    var debugName: String {
        abbreviatedTypeName(of: self)
    }

    var internalDescription: String {
        String(describing: Self.self)
    }
}
