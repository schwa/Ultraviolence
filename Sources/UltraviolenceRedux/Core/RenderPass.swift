@MainActor
public protocol View {
    associatedtype Body: View
    @MainActor @ViewBuilder var body: Body { get }
}

extension Never: View {
    public typealias Body = Never
}

public extension View where Body == Never {
    var body: Never {
        fatalError("`body` is not implemented for `Never` types.")
    }
}

internal extension View {
    func expandNode(_ node: Node) {
        // TODO: Refactor this to make expandion of the node tree distinct from handling observable and state properties.
        guard let graph = Graph.current else {
            fatalError("No graph is currently active.")
        }
        graph.activeNodeStack.append(node)
        defer {
            _ = graph.activeNodeStack.removeLast()
        }

        node.view = self

        if let builtInView = self as? BodylessView {
            builtInView._expandNode(node)
            return
        }

        let shouldRunBody = node.needsRebuild || !equalToPrevious(node)
        if !shouldRunBody {
            for child in node.children {
                child.rebuildIfNeeded()
            }
            return
        }

        observeObjects(node)
        restoreStateProperties(node)

        if node.children.isEmpty {
            node.children = [graph.makeNode()]
        }
        body.expandNode(node.children[0])

        storeStateProperties(node)
        node.previousView = self
        node.needsRebuild = false
    }

    private func equalToPrevious(_ node: Node) -> Bool {
        guard let previous = node.previousView as? Self else { return false }
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
