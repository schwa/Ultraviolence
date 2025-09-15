// TODO: #30 Make into actual modifier.
internal struct EnvironmentWritingModifier<Content: Element>: Element, BodylessElement {
    var content: Content
    var modify: (inout UVEnvironmentValues) -> Void

    func visitChildrenBodyless(_ visit: (any Element) throws -> Void) throws {
        try visit(content)
    }

    func configureNodeBodyless(_ node: Node) throws {
        modify(&node.environmentValues)
    }

    nonisolated func requiresSetup(comparedTo old: EnvironmentWritingModifier<Content>) -> Bool {
        // Environment changes might affect setup if they change pipeline-relevant values
        // Since we can't compare closures, be conservative
        return true
    }
}

public extension Element {
    func environment<Value>(_ keyPath: WritableKeyPath<UVEnvironmentValues, Value>, _ value: Value) -> some Element {
        EnvironmentWritingModifier(content: self) { environmentValues in
            environmentValues[keyPath: keyPath] = value
        }
    }
}
