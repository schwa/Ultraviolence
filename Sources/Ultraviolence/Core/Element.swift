import UltraviolenceSupport

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
        unreachable("`body` is not implemented for `Never` types (on \(self)).")
    }
}

internal extension Element {
    func expandNode(_ node: Node, context: ExpansionContext) throws {
        // TODO: #23 Refactor this to make expansion of the node tree distinct from handling observable and state properties.
        guard let graph = NodeGraph.current else {
            preconditionFailure("No graph is currently active.")
        }

        // TODO: #35 Avoid this in future
        let parent = graph.activeNodeStack.last !== node ? graph.activeNodeStack.last : nil

        graph.activeNodeStack.append(node)
        defer {
            _ = graph.activeNodeStack.removeLast()
        }

        node.element = self

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

        observeObjects(node)
        restoreStateProperties(node)

        if let bodylessElement = self as? any BodylessElement {
            try bodylessElement.expandIntoNode(node, context: context.deeper())
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
                let children = [graph.makeNode()]
                node.children = children
                children.forEach { child in
                    child.parent = node
                }
            }
            try body.expandNode(node.children[0], context: context.deeper())
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

public extension Node {
    var ancestors: [Node] {
        var ancestors: [Node] = []
        var current: Node = self
        while let parent = current.parent {
            ancestors.append(parent)
            current = parent
        }
        return ancestors
    }

    @MainActor
    var path: String {
        let ancestors = self.ancestors
        let path = ancestors.map(\.debugName).joined(separator: ".")
        return path + ".\(debugName)"
    }

    @MainActor
    var name: String {
        if let element {
            return "\(element.debugName)"
        }
        return "<nil>"
    }

    @MainActor
    var debugName: String {
        if let name = self.debugLabel {
            return name
        }
        if let element {
            return "\(element.debugName)"
        }
        return "<nil>"
    }
}

internal extension Element {
    var debugName: String {
        abbreviatedTypeName(of: self)
    }
}

internal func abbreviatedTypeName<T>(of t: T) -> String {
    let name = "\(type(of: t))"
    return String(name[..<(name.firstIndex(of: "<") ?? name.endIndex)])
}
