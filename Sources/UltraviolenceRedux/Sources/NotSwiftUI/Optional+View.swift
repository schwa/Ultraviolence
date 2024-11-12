extension Optional: View, BodylessView where Wrapped: View {
    public typealias Body = Never

    func _expandNode(_ node: Node) {
        self?.expandNode(node)
    }
}
