@MainActor
public protocol Element {
    associatedtype Body: Element
    @MainActor @ElementBuilder var body: Body { get throws }
}

extension Never: Element {
    public typealias Body = Never
}

public extension Element where Body == Never {
    var body: Never {
        preconditionFailure("`body` is not implemented for `Never` types (on \(self)).")
    }
}

internal extension Element {
    func expandNode(_ node: Node, depth: Int) throws {
        logger?.log("\(type(of: self)).\(#function) enter.")
        defer {
            logger?.log("\(type(of: self)).\(#function)")
        }

        // TODO: Refactor this to make expansion of the node tree distinct from handling observable and state properties.
        guard let graph = Graph.current else {
            preconditionFailure("No graph is currently active.")
        }

        let parent = graph.activeNodeStack.last

        graph.activeNodeStack.append(node)
        defer {
            _ = graph.activeNodeStack.removeLast()
        }

        node.element = self

        if let parentEnvironmentValues = parent?.environmentValues {
            node.environmentValues.values.merge(parentEnvironmentValues.values) { old, _ in old }
        }

        observeObjects(node)
        restoreStateProperties(node)

        if let bodylessElement = self as? any BodylessElement {
            try bodylessElement._expandNode(node, depth: depth + 1)
        }

        let shouldRunBody = node.needsRebuild || !equalToPrevious(node)
        if !shouldRunBody {
            for child in node.children {
                try child.rebuildIfNeeded()
            }
            return
        }

        if Body.self != Never.self {
            if node.children.isEmpty {
                node.children = [graph.makeNode()]
            }
            try body.expandNode(node.children[0], depth: depth + 1)
        }

        storeStateProperties(node)
        node.previousElement = self
        node.needsRebuild = false
    }

    private func equalToPrevious(_ node: Node) -> Bool {
        guard let previous = node.previousElement as? Self else {
            return false
        }
        let lhs = Mirror(reflecting: self).children
        let rhs = Mirror(reflecting: previous).children
        return zip(lhs, rhs).allSatisfy { lhs, rhs in
            guard lhs.label == rhs.label else {
                return false
            }
            if lhs.value is StateProperty {
                return true
            }
            if !isEqual(lhs.value, rhs.value) {
                return false
            }
            return true
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
