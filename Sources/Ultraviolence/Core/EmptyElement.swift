public struct EmptyElement: Element {
    public typealias Body = Never

    public init() {
        // This line intentionally left blank.
    }
}

extension EmptyElement: BodylessElement {
    internal func _expandNode(_ node: Node, context: ExpansionContext) throws {
        // This line intentionally left blank.
    }
}
