import UltraviolenceSupport

public extension System {
    @MainActor
    func processSetup() throws {
        try withIntervalSignpost(signposter, name: "System.processSetup()") {
            try process { element, node in
                try element.setupEnter(node)
            } exit: { element, node in
                try element.setupExit(node)
            }
        }
    }

    @MainActor
    func processWorkload() throws {
        try withIntervalSignpost(signposter, name: "System.processWorkload()") {
            try process { element, node in
                try element.workloadEnter(node)
            } exit: { element, node in
                try element.workloadExit(node)
            }
        }
    }
}

internal extension System {
    @MainActor
    func process(enter: (any BodylessElement, Node) throws -> Void, exit: (any BodylessElement, Node) throws -> Void) throws {
        try withCurrentSystem {
            assert(activeNodeStack.isEmpty)

            // Track nodes that have been entered but not yet exited
            var nodesNeedingExit: [Node] = []

            // Process nodes in depth-first order
            for identifier in orderedIdentifiers {
                guard let node = nodes[identifier] else {
                    continue
                }

                // Only process BodylessElements
                if let bodylessElement = node.element as? any BodylessElement {
                    // Exit any nodes that aren't ancestors of the current node
                    // This ensures sibling passes close their encoders before the next sibling starts
                    while !nodesNeedingExit.isEmpty {
                        guard let lastNode = nodesNeedingExit.last else {
                            fatalError("Unreachable")
                        }
                        if isDescendant(node, of: lastNode) {
                            // Current node is a child, keep parent's encoder open
                            break
                        }
                        // Current node is a sibling or in different branch, close the encoder
                        let nodeToExit = nodesNeedingExit.removeLast()
                        if let exitElement = nodeToExit.element as? any BodylessElement {
                            let ancestors = buildAncestorChain(for: nodeToExit)
                            for ancestor in ancestors {
                                activeNodeStack.append(ancestor)
                            }
                            activeNodeStack.append(nodeToExit)

                            try exit(exitElement, nodeToExit)

                            activeNodeStack.removeLast(ancestors.count + 1)
                        }
                    }

                    // Build the ancestor chain for proper environment inheritance
                    let ancestors = buildAncestorChain(for: node)

                    // Rebuild environment parent chain in case it was broken by COW
                    if !ancestors.isEmpty {
                        if node.environmentValues.storage.parent == nil {
                            if let parentNode = ancestors.last {
                                var freshEnvironment = UVEnvironmentValues()
                                freshEnvironment.merge(parentNode.environmentValues)
                                freshEnvironment.storage.values.merge(node.environmentValues.storage.values) { _, new in new }
                                node.environmentValues = freshEnvironment
                            }
                        }
                    }

                    // Push all ancestors onto the stack to maintain parent-child hierarchy
                    for ancestor in ancestors {
                        activeNodeStack.append(ancestor)
                    }

                    // Push current node
                    activeNodeStack.append(node)

                    try enter(bodylessElement, node)

                    // Remove from stack but track that this node needs exit
                    activeNodeStack.removeLast(ancestors.count + 1)
                    nodesNeedingExit.append(node)
                }
            }

            // Exit any remaining nodes in reverse order
            while !nodesNeedingExit.isEmpty {
                let node = nodesNeedingExit.removeLast()
                if let bodylessElement = node.element as? any BodylessElement {
                    let ancestors = buildAncestorChain(for: node)
                    for ancestor in ancestors {
                        activeNodeStack.append(ancestor)
                    }
                    activeNodeStack.append(node)

                    try exit(bodylessElement, node)

                    activeNodeStack.removeLast(ancestors.count + 1)
                }
            }

            assert(activeNodeStack.isEmpty)
        }
    }

    /// Check if a node is a descendant of another node
    private func isDescendant(_ node: Node, of potentialAncestor: Node) -> Bool {
        var currentId = node.parentIdentifier
        while let parentId = currentId {
            if parentId == potentialAncestor.id {
                return true
            }
            currentId = nodes[parentId]?.parentIdentifier
        }
        return false
    }

    /// Build the chain of ancestors from root to the parent of the given node
    private func buildAncestorChain(for node: Node) -> [Node] {
        var ancestors: [Node] = []
        var currentIdentifier = node.parentIdentifier

        while let identifier = currentIdentifier {
            guard let parentNode = nodes[identifier] else {
                break
            }
            // Insert at beginning to maintain root-to-parent order
            ancestors.insert(parentNode, at: 0)
            currentIdentifier = parentNode.parentIdentifier
        }

        return ancestors
    }
}
