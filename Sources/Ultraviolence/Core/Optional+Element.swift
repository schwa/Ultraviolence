extension Optional: Element, BodylessElement where Wrapped: Element {
    public typealias Body = Never

    internal func _expandNode(_ node: Node, depth: Int) throws {
        try self?.expandNode(node, depth: depth + 1)
    }
}
