internal extension Element {
    // TODO: RENAME THIS
    func system_configureNode(_ node: NeoNode) throws {
        guard let system = System.current else {
            preconditionFailure("No System is currently active.")
        }

        // TODO: #35 Avoid this in future
        // Get the parent node (second to last in stack, since current node is already pushed)
        let parent = system.activeNodeStack.count >= 2 ? system.activeNodeStack[system.activeNodeStack.count - 2] : nil

        system_applyInheritedEnvironment(from: parent, to: node)

        system_observeObjects(node)
        system_restoreStateProperties(node)

        if let bodylessElement = self as? any BodylessElement {
            try bodylessElement.system_configureNodeBodyless(node)
        }
        system_storeStateProperties(node)
    }

    private func system_applyInheritedEnvironment(from parent: NeoNode?, to node: NeoNode) {
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

    private func system_observeObjects(_ node: NeoNode) {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            guard let observedObject = child.value as? AnyObservedObject else {
                return
            }
            observedObject.addDependency(node)
        }
    }

    private func system_restoreStateProperties(_ node: NeoNode) {
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

    private func system_storeStateProperties(_ node: NeoNode) {
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

