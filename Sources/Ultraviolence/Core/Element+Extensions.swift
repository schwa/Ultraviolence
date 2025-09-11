
// TODO: Let's organise these extensions better

internal extension Element {
    var debugName: String {
        abbreviatedTypeName(of: self)
    }

    var internalDescription: String {
        String(describing: Self.self)
    }
}
