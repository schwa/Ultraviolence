extension Optional: Element, BodylessElement where Wrapped: Element {
    public typealias Body = Never

    func _expandNode(_ node: Node) throws {
        try self?.expandNode(node)
    }
}
