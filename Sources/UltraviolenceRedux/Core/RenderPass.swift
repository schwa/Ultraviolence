@MainActor
// TODO: This _cannot_ be called a RenderPass. It's a lower-level building block object. We can't call it Node because nodes exist.
public protocol RenderPass {
    associatedtype Body: RenderPass
    @MainActor @RenderPassBuilder var body: Body { get }
}

extension Never: RenderPass {
    public typealias Body = Never
}

public extension RenderPass where Body == Never {
    var body: Never {
        fatalError("`body` is not implemented for `Never` types (on \(self)).")
    }
}

internal extension RenderPass {
    func expandNode(_ node: Node) {
        // TODO: Refactor this to make expandion of the node tree distinct from handling observable and state properties.
        guard let graph = Graph.current else {
            fatalError("No graph is currently active.")
        }

        let parent = graph.activeNodeStack.last

        graph.activeNodeStack.append(node)
        defer {
            _ = graph.activeNodeStack.removeLast()
        }

        node.renderPass = self

        if let parentEnvironmentValues = parent?.environmentValues {
            node.environmentValues.values.merge(parentEnvironmentValues.values) { old, _ in old }
        }

        observeObjects(node)
        restoreStateProperties(node)

        if let builtInRenderPass = self as? any BodylessRenderPass {
            builtInRenderPass._expandNode(node)
        }

        let shouldRunBody = node.needsRebuild || !equalToPrevious(node)
        if !shouldRunBody {
            for child in node.children {
                child.rebuildIfNeeded()
            }
            return
        }

        if Body.self != Never.self {
            if node.children.isEmpty {
                node.children = [graph.makeNode()]
            }
            body.expandNode(node.children[0])
        }

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
