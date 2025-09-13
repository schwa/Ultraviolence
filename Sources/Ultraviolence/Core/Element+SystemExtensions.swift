internal extension Element {
    // TODO: RENAME THIS
    func configureNode(_ node: Node) throws {
        guard let system = System.current else {
            preconditionFailure("No System is currently active.")
        }

        // TODO: #35 Avoid this in future
        // Get the parent node (second to last in stack, since current node is already pushed)
        let parent = system.activeNodeStack.count >= 2 ? system.activeNodeStack[system.activeNodeStack.count - 2] : nil

        applyInheritedEnvironment(from: parent, to: node)

        observeObjects(node)
        restoreStateProperties(node)

        if let bodylessElement = self as? any BodylessElement {
            try bodylessElement.configureNodeBodyless(node)
        }
        storeStateProperties(node)
    }

    private func applyInheritedEnvironment(from parent: Node?, to node: Node) {
        // Always create a fresh environment for the node to avoid cycles
        // This ensures each node has its own storage that can safely inherit from parent
        if let parentEnvironmentValues = parent?.environmentValues {
            // Create a fresh environment that inherits from parent
            var freshEnvironment = UVEnvironmentValues()
            freshEnvironment.merge(parentEnvironmentValues)

            // Preserve any existing values from the node's current environment
            if !node.environmentValues.storage.values.isEmpty {
                freshEnvironment.storage.values.merge(node.environmentValues.storage.values) { _, new in new }
            }

            node.environmentValues = freshEnvironment
        }
    }

    private func observeObjects(_ node: Node) {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            guard let observedObject = child.value as? AnyObservedObject else {
                return
            }
            observedObject.addDependency(node)
        }
    }

    private func restoreStateProperties(_ node: Node) {
        let mirror = Mirror(reflecting: self)
        for (label, value) in mirror.children {
            guard let prop = value as? StateProperty else { continue }
            guard let label else {
                preconditionFailure("No label for state property.")
            }
            guard let propValue = node.stateProperties[label] else { continue }
            prop.erasedValue = propValue
        }
    }

    private func storeStateProperties(_ node: Node) {
        let m = Mirror(reflecting: self)
        for (label, value) in m.children {
            guard let prop = value as? StateProperty else { continue }
            guard let label else {
                preconditionFailure("No label for state property.")
            }
            node.stateProperties[label] = prop.erasedValue
        }
    }
}

