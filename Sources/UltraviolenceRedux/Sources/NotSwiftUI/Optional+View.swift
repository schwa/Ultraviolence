extension Optional: View, BuiltinView where Wrapped: View {
    public typealias Body = Never

    func _buildNodeTree(_ node: Node) {
        map(AnyBuiltinView.init)?._buildNodeTree(node)
    }
}
