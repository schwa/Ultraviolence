@MainActor
public protocol RenderPass {
    associatedtype Body: RenderPass
    @MainActor @RenderPassBuilder var body: Body { get }
}

extension Never: RenderPass {
    public typealias Body = Never
}

public extension RenderPass where Body == Never {
    var body: Never {
        fatalError("`body` is not implemented for `Never` types.")
    }
}

internal extension RenderPass {
    func buildNodeTree(_ node: Node) {
        guard let graph = Graph.current else {
            fatalError("No graph is currently active.")
        }
        graph.activeNodeStack.append(node)


        if let builtInRenderPass = self as? BuiltinRenderPass {
            node.renderPass = builtInRenderPass
            builtInRenderPass._buildNodeTree(node)
            return
        }

        defer {
            _ = graph.activeNodeStack.removeLast()
        }

        let shouldRunBody = node.needsRebuild || !equalToPrevious(node)
        if !shouldRunBody {
            for child in node.children {
                child.rebuildIfNeeded()
            }
            return
        }

        node.renderPass = AnyBuiltinRenderPass(self)

        observeObjects(node)
        restoreStateProperties(node)

        if node.children.isEmpty {
            node.children = [Node(graph: node.graph)]
        }
        body.buildNodeTree(node.children[0])

        storeStateProperties(node)
        node.previousRenderPass = self
        node.needsRebuild = false
    }

    private func equalToPrevious(_ node: Node) -> Bool {
        guard let previous = node.previousRenderPass as? Self else { return false }
        let lhs = Mirror(reflecting: self).children
        let rhs = Mirror(reflecting: previous).children
        return zip(lhs, rhs).allSatisfy { lhs, rhs in
            guard lhs.label == rhs.label else { return false }
            if lhs.value is StateProperty { return true }
            if !isEqual(lhs.value, rhs.value) { return false }
            return true
        }
    }

    private func observeObjects(_ node: Node) {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            guard let observedObject = child.value as? AnyObservedObject else { return }
            observedObject.addDependency(node)
        }
    }

    private func restoreStateProperties(_ node: Node) {
        let mirror = Mirror(reflecting: self)
        for (label, value) in mirror.children {
            guard let prop = value as? StateProperty else { continue }
            guard let label else {
                fatalError("No label for state property.")
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
                fatalError("No label for state property.")
            }
            node.stateProperties[label] = prop.erasedValue
        }
    }
}
