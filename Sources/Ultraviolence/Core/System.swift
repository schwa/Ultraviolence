internal import os

public class System {
    // TODO: #221 These properties should become private to enforce proper encapsulation
    var orderedIdentifiers: [StructuralIdentifier] = []
    var nodes: [StructuralIdentifier: Node] = [:]
    /// Stack of nodes currently being processed during system traversal.
    /// This stack is maintained during:
    /// - Initial system update (`update(root:)`) - populated during element tree traversal
    /// - Setup phase (`setup()`) - populated during node visitation
    /// - Process/workload phase (`process()`) - populated during node visitation
    ///
    /// The stack enables:
    /// - Environment value resolution via @UVEnvironment property wrapper
    /// - State dependency tracking for reactive updates
    /// - Parent-child context during node configuration
    ///
    /// IMPORTANT: The stack is empty outside of these traversal contexts.
    /// Accessing @UVEnvironment properties outside traversal will cause a crash.
    var activeNodeStack: [Node] = []
    var dirtyIdentifiers: Set<StructuralIdentifier> = []

    private static let _current = OSAllocatedUnfairLock<System?>(uncheckedState: nil)

    internal static var current: System? {
        get {
            _current.withLockUnchecked { $0 }
        }
        set {
            _current.withLockUnchecked { $0 = newValue }
        }
    }

    public init() {
        // This line intentionally left blank.
    }
    
    /// Mark all nodes as needing setup (e.g., when drawable size changes)
    public func markAllNodesNeedingSetup() {
        for node in nodes.values {
            node.needsSetup = true
        }
    }

    @MainActor
    public func update(root: some Element) throws {
        assert(activeNodeStack.isEmpty)
        try withCurrentSystem {
            // Clean up after the update
            defer {
                assert(activeNodeStack.isEmpty, "activeNodeStack should be empty after update")
                dirtyIdentifiers = []
                activeNodeStack.removeAll()
            }

            // Create iterator for previous identifiers
            var previousIterator = orderedIdentifiers.makeIterator()

            // New identifiers we're building
            var newOrderedIdentifiers: [StructuralIdentifier] = []

            // New nodes dictionary we're building
            var newNodes: [StructuralIdentifier: Node] = [:]

            // Stack of atoms to build current path
            var atomStack: [StructuralIdentifier.Atom] = []

            // Sibling indices at each level (stack of dictionaries)
            var siblingIndices: [[ElementTypeIdentifier: Int]] = [[:]  ]

            // Helper to get next index for a type at current level
            func nextIndex(for typeId: ElementTypeIdentifier) -> Int {
                let currentLevel = siblingIndices.count - 1
                let index = siblingIndices[currentLevel][typeId] ?? 0
                siblingIndices[currentLevel][typeId] = index + 1
                return index
            }

            // Process a single element
            @MainActor func processElement(_ element: any Element) throws {
                // Create atom for this element
                let typeId = ElementTypeIdentifier(type(of: element))
                let index = nextIndex(for: typeId)
                let atom = StructuralIdentifier.Atom(typeIdentifier: typeId, index: index)

                // Push atom onto stack
                atomStack.append(atom)
                defer { atomStack.removeLast() }

                // Build current identifier from stack
                let currentId = StructuralIdentifier(atoms: atomStack)
                newOrderedIdentifiers.append(currentId)

                // Get previous identifier
                let previousId = previousIterator.next()

                // Get or create the node for this element
                let currentNode: Node

                // Compare and update nodes
                currentNode = processNode(currentId: currentId, previousId: previousId, element: element, newNodes: &newNodes)

                // Push current node onto active stack
                activeNodeStack.append(currentNode)
                defer { activeNodeStack.removeLast() }

                // Configure the node (applies environment, state, etc.)
                try element.configureNode(currentNode)

                // Walk children
                siblingIndices.append([:]) // Push new level for children
                defer { siblingIndices.removeLast() } // Pop when done

                try element.visitChildren { child in
                    try processElement(child)
                }
            }

            // Process root
            try processElement(root)

            // Clear dirty identifiers after processing entire tree
            dirtyIdentifiers = []

            // Find removed nodes by diffing old vs new
            let removedIds = Set(nodes.keys).subtracting(Set(newNodes.keys))
            for _ in removedIds {
                // TODO: #222 Could call cleanup/onDisappear here for proper node lifecycle management
            }

            // Replace old with new
            self.nodes = newNodes
            self.orderedIdentifiers = newOrderedIdentifiers
        }
    }
}

// MARK: - Private Node Processing

private extension System {
    /// Determine whether to reuse an existing node or create a new one
    func processNode(currentId: StructuralIdentifier, previousId: StructuralIdentifier?, element: any Element, newNodes: inout [StructuralIdentifier: Node]) -> Node {
        if let previousId, previousId == currentId {
            return reuseNode(currentId: currentId, element: element, newNodes: &newNodes)
        }
        return makeNode(currentId: currentId, element: element, newNodes: &newNodes)
    }

    /// Reuse an existing node, updating it if its element has changed
    func reuseNode(currentId: StructuralIdentifier, element: any Element, newNodes: inout [StructuralIdentifier: Node]) -> Node {
        guard let existingNode = nodes[currentId] else {
            // This should never happen - same ID but no existing node
            fatalError("Found matching structural ID \(currentId) but no existing node - this indicates a bug in the System")
        }
        // Update parent identifier (in case the node moved in the tree)
        existingNode.parentIdentifier = activeNodeStack.last?.id

        if shouldUpdateNode(existingNode, with: element, id: currentId) {
            existingNode.element = element
            // When element changes, preserve setup-phase values while clearing others
            // This ensures values like renderPipelineState set during setup are retained
            let preservedValues = existingNode.environmentValues.storage.values
            existingNode.environmentValues = UVEnvironmentValues()
            // Restore preserved values after resetting
            existingNode.environmentValues.storage.values = preservedValues
            // Element changed, needs setup
            existingNode.needsSetup = true
        }
        // Whether changed or not, reuse the existing node
        newNodes[currentId] = existingNode
        return existingNode
    }

    func makeNode(currentId: StructuralIdentifier, element: any Element, newNodes: inout [StructuralIdentifier: Node]) -> Node {
        let parentId = activeNodeStack.last?.id
        let currentNode = Node(system: self, id: currentId, parentIdentifier: parentId, element: element)
        newNodes[currentId] = currentNode
        // New nodes always need setup
        currentNode.needsSetup = true
        return currentNode
    }

    func shouldUpdateNode(_ node: Node, with element: any Element, id: StructuralIdentifier) -> Bool {
        !isEqual(node.element, element) || dirtyIdentifiers.contains(id)
    }
}
