/// A type-erased View wrapper that converts a View to a BuiltinView.
internal struct AnyBuiltinView: BuiltinView {
    private var buildNodeTree: (Node) -> ()

    @MainActor
    var viewType: Any

    @MainActor
    init<V: View>(_ view: V) {
        buildNodeTree = view.buildNodeTree(_:)
        viewType = type(of: view)
    }

    @MainActor
    func _buildNodeTree(_ node: Node) {
        buildNodeTree(node)
    }
}

extension AnyBuiltinView: @preconcurrency CustomDebugStringConvertible {
    var debugDescription: String {
        "AnyBuiltinView(\(viewType))"
    }
}
