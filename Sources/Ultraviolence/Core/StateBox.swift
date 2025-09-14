internal final class StateBox<Wrapped> {
    private var _value: Wrapped
    private weak var _system: System?
    private var dependencies: [WeakBox<Node>] = []
    private var hasBeenConnected = false

    private var system: System? {
        if _system == nil {
            _system = System.current
            if _system != nil {
                hasBeenConnected = true
            } else if !hasBeenConnected {
                // Never been connected to a graph - this is a real error, else: was connected but graph is now gone (teardown) - this is OK
                assert(false, "StateBox must be used within a System.")
            }
        }
        return _system
    }

    internal var wrappedValue: Wrapped {
        get {
            // Remove dependnecies whose values have been deallocated
            dependencies = dependencies.filter { $0.wrappedValue != nil }

            // Add current node accessoring the value to list of dependencies
            let currentNode = system?.activeNodeStack.last
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

    internal var binding: UVBinding<Wrapped> = UVBinding(
        get: { preconditionFailure("Empty Binding: get() called.") },
        set: { _ in preconditionFailure("Empty Binding: set() called.") }
    )

    internal init(_ wrappedValue: Wrapped) {
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
    private func valueDidChange() {
        guard let system else {
            // TODO: #218 Handle error when system is nil during value change - could log or assert
            return
        }
        dependencies.forEach { boxedNode in
            guard let node = boxedNode() else {
                // TODO: #218 Handle error when node has been deallocated - dependency cleanup needed
                return
            }
            system.dirtyIdentifiers.insert(node.id)
        }
    }
}
