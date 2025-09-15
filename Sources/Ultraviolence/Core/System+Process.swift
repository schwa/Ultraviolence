import UltraviolenceSupport

public extension System {
    @MainActor
    func processSetup() throws {
        try withIntervalSignpost(signposter, name: "System.processSetup()") {
            try process(needsSetup: true) { element, node in
                try element.setupEnter(node)
            } exit: { element, node in
                try element.setupExit(node)
                node.needsSetup = false
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
    func process(needsSetup: Bool = false, enter: (any BodylessElement, Node) throws -> Void, exit: (any BodylessElement, Node) throws -> Void) throws {
        try withCurrentSystem {
            assert(activeNodeStack.isEmpty)
            for event in traversalEvents {
                switch event {
                case .enter(let node):
                    activeNodeStack.append(node)
                    if let bodylessElement = node.element as? any BodylessElement, !needsSetup || node.needsSetup {
                        // Rebuild environment parent chain
                        // TODO: Investigate whether we need this still. Seems like patch for broken behavior.
                        if activeNodeStack.count > 1 {
                            if node.environmentValues.storage.parent == nil {
                                let parentNode = activeNodeStack[activeNodeStack.count - 2]
                                var freshEnvironment = UVEnvironmentValues()
                                freshEnvironment.merge(parentNode.environmentValues)
                                freshEnvironment.storage.values.merge(node.environmentValues.storage.values) { _, new in new }
                                node.environmentValues = freshEnvironment
                            }
                        }
                        try enter(bodylessElement, node)
                    }
                case .exit(let node):
                    if let bodylessElement = node.element as? any BodylessElement, !needsSetup || node.needsSetup {
                        try exit(bodylessElement, node)
                    }
                    activeNodeStack.removeLast()
                }
            }
            assert(activeNodeStack.isEmpty)
        }
    }
}
