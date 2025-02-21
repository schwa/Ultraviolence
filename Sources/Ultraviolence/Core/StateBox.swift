internal final class StateBox<Wrapped> {
    private var _value: Wrapped
    private weak var _graph: Graph?
    private var dependencies: [WeakBox<Node>] = []

    var graph: Graph? {
        if _graph == nil {
            _graph = Graph.current
            assert(_graph != nil, "StateBox must be used within a Graph.")
        }
        return _graph
    }

    var wrappedValue: Wrapped {
        get {
            // Remove dependnecies whose values have been deallocated
            dependencies = dependencies.filter { $0.wrappedValue != nil }

            // Add current node accessoring the value to list of dependencies
            let currentNode = graph?.activeNodeStack.last
            if let currentNode, !dependencies.contains(where: { $0() === currentNode }) {
                dependencies.append(WeakBox(currentNode))
            }
            return _value
        }
        set {
            _value = newValue
            valueDidChange()
        }
    }

    var binding: UVBinding<Wrapped> = UVBinding(
        get: { preconditionFailure("Empty Binding: get() called.") },
        set: { _ in preconditionFailure("Empty Binding: set() called.") }
    )

    init(_ wrappedValue: Wrapped) {
        self._value = wrappedValue
        // swiftlint:disable:next unowned_variable_capture
        self.binding = UVBinding(get: { [unowned self] in
            self.wrappedValue
            // swiftlint:disable:next unowned_variable_capture
        }, set: { [unowned self] newValue in
            self.wrappedValue = newValue
        })
    }

    /// Update dependencies when the value changes
    func valueDidChange() {
        dependencies.forEach { $0()?.setNeedsRebuild() }
    }
}
