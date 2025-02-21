public struct EmptyElement: Element {
    public typealias Body = Never

    public init() {
        // This line intentionally left blank.
    }
}

extension EmptyElement: BodylessElement {
    func _expandNode(_ node: Node, depth: Int) throws {
        // This line intentionally left blank.
    }
}
