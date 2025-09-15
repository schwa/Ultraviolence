import UltraviolenceSupport

public extension System {
    @MainActor
    func processSetup() throws {
        // Walk the traversal events directly - much simpler!
        try withIntervalSignpost(signposter, name: "System.processSetup()") {
            try withCurrentSystem {
                assert(activeNodeStack.isEmpty)
                
                // Process each traversal event
                for event in traversalEvents {
                    switch event {
                    case .enter(let node):
                        // Only process BodylessElements that need setup
                        if let bodylessElement = node.element as? any BodylessElement, node.needsSetup {
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
                            
                            try bodylessElement.setupEnter(node)
                            
                            // Remove from stack
                            activeNodeStack.removeLast(ancestors.count + 1)
                        }
                        
                    case .exit(let node):
                        // Only process BodylessElements that need setup
                        if let bodylessElement = node.element as? any BodylessElement, node.needsSetup {
                            let ancestors = buildAncestorChain(for: node)
                            for ancestor in ancestors {
                                activeNodeStack.append(ancestor)
                            }
                            activeNodeStack.append(node)
                            
                            try bodylessElement.setupExit(node)
                            node.needsSetup = false
                            
                            activeNodeStack.removeLast(ancestors.count + 1)
                        }
                    }
                }
                
                assert(activeNodeStack.isEmpty)
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
        // Walk the traversal events directly - much simpler!
        try withCurrentSystem {
            assert(activeNodeStack.isEmpty)

            // Process each traversal event
            for event in traversalEvents {
                switch event {
                case .enter(let node):
                    // Only process BodylessElements
                    if let bodylessElement = node.element as? any BodylessElement {
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

                        // Remove from stack
                        activeNodeStack.removeLast(ancestors.count + 1)
                    }
                    
                case .exit(let node):
                    // Only process BodylessElements
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
            }

            assert(activeNodeStack.isEmpty)
        }
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
